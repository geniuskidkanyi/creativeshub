# Records scans of a rotating QR code. A code that was scanned while live
# stays usable for IN_USE_WINDOW after its most recent use — every scan (and
# payment initiation) extends the window — so the customer can reload, finish
# checkout, or come back from the payment gateway without the code rotting
# under them.
class QrScan < ApplicationRecord
  IN_USE_WINDOW = 5.minutes

  belongs_to :account

  # Uniqueness of [account_id, step] is enforced by the DB index so that
  # concurrent first scans race safely (see Account#register_qr_scan).
  validates :step, presence: true

  scope :in_use, -> { where("updated_at > ?", IN_USE_WINDOW.ago) }
end
