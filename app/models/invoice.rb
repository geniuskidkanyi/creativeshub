class Invoice < ApplicationRecord
  belongs_to :account
  belongs_to :client
  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :invoice_items, allow_destroy: true, reject_if: :all_blank

  enum :status, { draft: "draft", sent: "sent", paid: "paid", overdue: "overdue", cancelled: "cancelled" }

  validates :invoice_number, uniqueness: { scope: :account_id }, allow_nil: true
  validates :status, presence: true

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

  private

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
