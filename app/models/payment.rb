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
    invoice&.client&.name || "QR payment"
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
