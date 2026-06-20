class Payment < ApplicationRecord
  belongs_to :invoice

  enum :status, { pending: "pending", succeeded: "succeeded", failed: "failed" }
  enum :payment_method, { payment_request: "payment_request", payment_session: "payment_session" }

  validates :waychit_id, uniqueness: true, allow_nil: true

  scope :succeeded, -> { where(status: :succeeded) }

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
end
