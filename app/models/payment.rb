class Payment < ApplicationRecord
  belongs_to :invoice, optional: true
  belongs_to :account

  enum :status, { pending: "pending", succeeded: "succeeded", failed: "failed" }
  enum :payment_method, { payment_request: "payment_request", payment_session: "payment_session" }

  before_validation { self.account_id ||= invoice&.account_id }

  validates :waychit_id, uniqueness: true, allow_nil: true

  scope :succeeded, -> { where(status: :succeeded) }

  # Succeeded payments drive the dashboard list and the payout balance, so
  # entering or leaving that state refreshes both live.
  after_commit :broadcast_account_refresh,
               if: -> { saved_change_to_status? && (succeeded? || status_previously_was == "succeeded") }

  def qr_payment?
    invoice_id.nil?
  end

  def payer_label
    invoice&.client&.name || customer_name || "QR payment"
  end

  # Fields reported by the Modem Pay charge webhook, when present.
  def channel = webhook_data&.dig("payment_method").presence
  def payer_wallet = webhook_data&.dig("payment_account").presence
  def customer_name = webhook_data&.dig("customer_name").presence
  def customer_contact = webhook_data&.dig("customer_phone").presence || webhook_data&.dig("customer_email").presence
  def test_mode? = webhook_data&.dig("test_mode") == true

  def gateway_fee_paid_by
    webhook_data&.dig("transaction_fee_type").presence
  end

  # The gateway reports money in its own scale; only translate the fee when
  # its reported amount lines up with ours (same unit, or minor units x100).
  def gateway_fee
    fee = webhook_data&.dig("transaction_fee").to_d
    return if fee.zero? || amount.to_d.zero?

    case webhook_data["amount"].to_d / amount.to_d
    when 1 then fee
    when 100 then fee / 100
    end
  end

  def mark_succeeded!(transaction_ref:, paid_at: Time.current)
    update!(
      status: :succeeded,
      transaction_reference: transaction_ref,
      paid_at: paid_at
    )
  end

  def mark_failed!
    update!(status: :failed)
  end

  private

  def broadcast_account_refresh
    return unless account

    if succeeded? && account.payments.succeeded.where.not(id: id).exists?
      # The list is already on screen: keep its rows and slot this one in.
      account.broadcast_new_payment(self)
    else
      # First payment (the card itself must appear) or a payment leaving
      # succeeded: redraw the whole section.
      account.broadcast_revenue_refresh
    end
  end
end
