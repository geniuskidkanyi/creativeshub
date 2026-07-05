# Records the first scan of a rotating QR code. A code that was scanned while
# live stays usable for IN_USE_WINDOW after that first scan, so the customer
# can reload or finish checkout without the code rotting under them.
class QrScan < ApplicationRecord
  IN_USE_WINDOW = 5.minutes

  belongs_to :account

  # Uniqueness of [account_id, step] is enforced by the DB index so that
  # concurrent first scans race safely (see Account#register_qr_scan).
  validates :step, presence: true

  scope :in_use, -> { where("created_at > ?", IN_USE_WINDOW.ago) }
end
