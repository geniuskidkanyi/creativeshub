class WebhookEvent < ApplicationRecord
  enum :status, { received: "received", processed: "processed", failed: "failed" }

  validates :event_id, presence: true, uniqueness: true

  def mark_processed!
    update!(status: :processed, processed_at: Time.current)
  end

  def mark_failed!
    update!(status: :failed)
  end
end
