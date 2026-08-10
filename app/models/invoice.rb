class Invoice < ApplicationRecord
  include Currencies

  belongs_to :account
  belongs_to :client

  # Invoices are looked up by number far more than by fuzzy text, and invoice
  # numbers run in sequence (…0006, 0007, 0008). Full-text/trigram either
  # misses a partial number ("0007") or floods the results with its
  # neighbours, so a plain substring match is both more precise and more
  # predictable here. Searches number, notes, and the billed client.
  def self.search_all(query)
    term = "%#{sanitize_sql_like(query.to_s.strip)}%"
    left_joins(:client)
      .where(
        "invoices.invoice_number ILIKE :t OR invoices.notes ILIKE :t OR " \
        "clients.name ILIKE :t OR clients.company ILIKE :t OR clients.email ILIKE :t",
        t: term
      )
      .distinct
  end
  belongs_to :recurring_invoice, optional: true
  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :invoice_items, allow_destroy: true, reject_if: :all_blank

  enum :status, { draft: "draft", sent: "sent", paid: "paid", overdue: "overdue", cancelled: "cancelled" }

  validates :invoice_number, uniqueness: { scope: :account_id }, allow_nil: true
  validates :status, presence: true
  validates :currency, inclusion: { in: CURRENCIES.keys }
  validates :fx_rate, numericality: { greater_than: 0 }

  before_validation :normalize_currency
  before_create :generate_invoice_number
  before_create :generate_public_token
  before_create :generate_uuid
  before_save :calculate_totals

  scope :ordered, -> { order(created_at: :desc) }
  scope :for_account, ->(account) { where(account: account) }

  # Invoice URLs use the UUID rather than the sequential id.
  def to_param
    uuid
  end

  def mark_as_sent!
    update!(status: :sent)
  end

  # Recorded when the invoice email is (re)sent to the client.
  def mark_email_sent!
    update_columns(email_sent_at: Time.current, updated_at: Time.current)
  end

  def emailed? = email_sent_at.present?
  def email_opened? = email_opened_at.present?

  # Called by the tracking pixel. First open sets the timestamp; every open
  # bumps the count. update_columns avoids callbacks/validations on a hot,
  # unauthenticated path.
  def register_email_open!
    now = Time.current
    update_columns(
      email_opened_at: email_opened_at || now,
      email_opens: email_opens + 1,
      updated_at: now
    )
  end

  def mark_as_paid!(method: nil, paid_at: Time.current)
    update!(status: :paid, payment_method: method, paid_date: paid_at)
  end

  def overdue?
    !paid? && due_date.present? && due_date < Date.current
  end

  def calculate_totals
    self.subtotal = invoice_items.reject(&:marked_for_destruction?).sum { |item| (item.quantity || 0) * (item.unit_price || 0) }
    self.tax_rate ||= 0
    self.tax_amount = (subtotal * tax_rate / 100.0).round(2)
    self.total_amount = (subtotal + tax_amount).round(2)
  end

  # The invoice total converted to GMD at its locked rate — this is what the
  # customer is actually charged, so a non-GMD invoice still settles into the
  # account's GMD balance. GMD invoices convert at 1.
  def gmd_total
    ((total_amount || 0) * (fx_rate || 1)).round(2)
  end

  private

  # GMD is the base currency and never carries a rate other than 1; clearing
  # any stray value keeps gmd_total honest.
  def normalize_currency
    self.currency = BASE_CURRENCY if currency.blank?
    self.fx_rate = 1 if base_currency?
  end

  def generate_invoice_number
    return if invoice_number.present?

    count = account.invoices.count + 1
    self.invoice_number = "INV-#{Date.current.year}-#{count.to_s.rjust(4, "0")}"
  end

  def generate_public_token
    return if public_token.present?
    self.public_token = SecureRandom.urlsafe_base64(16)
  end

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
