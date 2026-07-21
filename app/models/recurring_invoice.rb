class RecurringInvoice < ApplicationRecord
  include Currencies
  include PgSearch::Model

  belongs_to :account
  belongs_to :client

  pg_search_scope :search_all,
                  against: [ :title ],
                  associated_against: { client: [ :name, :company, :email ] },
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.3, word_similarity: true }
                  }

  has_many :recurring_invoice_items, -> { order(:position, :id) }, dependent: :destroy
  has_many :invoices, dependent: :nullify

  accepts_nested_attributes_for :recurring_invoice_items, allow_destroy: true, reject_if: :all_blank

  enum :status, { active: "active", paused: "paused", ended: "ended" }

  FREQUENCIES = {
    "weekly" => 1.week,
    "biweekly" => 2.weeks,
    "monthly" => 1.month,
    "quarterly" => 3.months,
    "yearly" => 1.year
  }.freeze

  validates :frequency, inclusion: { in: FREQUENCIES.keys }
  validates :interval, numericality: { greater_than: 0, only_integer: true }
  validates :start_date, presence: true
  validates :due_in_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :currency, inclusion: { in: CURRENCIES.keys }
  validates :fx_rate, numericality: { greater_than: 0 }
  validate :start_date_not_in_past
  validate :end_date_after_start_date
  validate :must_have_items

  before_validation :set_initial_next_run
  before_validation :normalize_currency

  scope :ordered, -> { order(:next_run_on) }
  # The generator's work queue: schedules whose cursor has come due. Using
  # <= rather than == means a day the worker was down is caught up on the
  # next run instead of being skipped.
  scope :due, ->(on = Date.current) { active.where(next_run_on: ..on) }

  def period = FREQUENCIES.fetch(frequency, 1.month) * interval

  def schedule_description
    every = interval == 1 ? frequency.capitalize : "Every #{interval} #{frequency.sub(/ly\z/, '')}s"
    [ every, ("until #{end_date.to_fs(:long)}" if end_date), ("· #{max_occurrences} total" if max_occurrences) ].compact.join(" ")
  end

  def subtotal
    recurring_invoice_items.sum { |item| (item.quantity || 0) * (item.unit_price || 0) }
  end

  def estimated_total
    (subtotal * (1 + (tax_rate || 0) / 100.0)).round(2)
  end

  # True once the schedule has produced everything it was asked to produce.
  def finished?(on = Date.current)
    return true if max_occurrences.present? && occurrences_count >= max_occurrences
    return true if end_date.present? && on > end_date
    false
  end

  def advance_cursor!(from)
    next_date = (from + period).to_date
    increment(:occurrences_count)
    self.last_run_on = from
    self.next_run_on = next_date
    self.status = :ended if finished?(next_date)
    save!
  end

  private

  def set_initial_next_run
    self.next_run_on ||= start_date
  end

  # No invoice may be dated in the past. Only enforced when the date is being
  # set or changed, so editing an existing schedule (whose first run may long
  # since have passed) doesn't fail on its historical start date.
  def start_date_not_in_past
    return if start_date.blank? || !start_date_changed?
    errors.add(:start_date, "can't be in the past") if start_date < Date.current
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be after the start date") if end_date < start_date
  end

  def must_have_items
    return if recurring_invoice_items.reject(&:marked_for_destruction?).any?
    errors.add(:base, "Add at least one line item")
  end

  def normalize_currency
    self.currency = BASE_CURRENCY if currency.blank?
    self.fx_rate = 1 if base_currency?
  end
end
