class Account < ApplicationRecord
  has_one_attached :logo

  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :payouts, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :qr_scans, dependent: :destroy

  validates :business_name, presence: true

  before_create :issue_qr_credentials
  after_commit :sync_modempay_sub_account, if: :requires_modempay_sync?

  # Rotating QR: a new code every QR_STEP_SECONDS. The code embeds the minute
  # timestep, which only ever increases, so no code is ever issued twice.
  QR_STEP_SECONDS = 60
  QR_GRACE_STEPS = 1

  MODEMPAY_PLATFORM_PERCENT = 1
  MODEMPAY_BUSINESS_PERCENT = 99

  def owner
    users.find_by(role: :owner)
  end

  def modempay_sub_account_ready?
    settlement_code.present? && settlement_account_number.present?
  end

  # The business's share of everything collected through Modem Pay.
  def total_earnings
    payments.succeeded.sum(:amount) * MODEMPAY_BUSINESS_PERCENT / 100.0
  end

  def total_paid_out
    payouts.counted_against_balance.sum("amount + COALESCE(fee, 0)")
  end

  def available_payout_balance
    [ total_earnings - total_paid_out, 0 ].max
  end

  # Live figures: dashboard and payout pages subscribe with
  # turbo_stream_from(account); these push refreshed partials over Action
  # Cable whenever money moves. Targets missing from the open page are
  # silently ignored by Turbo.
  def broadcast_revenue_refresh
    broadcast_replace_to self, target: "recent_payments", partial: "dashboard/recent_payments", locals: { account: self }
    broadcast_balance_refresh
  end

  # Slots a newly succeeded payment on top of the visible list, leaving the
  # existing rows in place. The row's dom_id keeps re-deliveries idempotent.
  def broadcast_new_payment(payment)
    broadcast_prepend_to self, target: "recent_payments_list", partial: "dashboard/payment", locals: { payment: payment }
    broadcast_balance_refresh
  end

  def broadcast_balance_refresh
    broadcast_replace_to self, target: "payout_summary", partial: "payouts/summary", locals: { account: self }
    broadcast_replace_to self, target: "payout_available_balance", partial: "payouts/available_balance", locals: { account: self }
  end

  def current_qr_code(at: Time.current)
    step = at.to_i / QR_STEP_SECONDS
    "#{step}-#{qr_signature(step)}"
  end

  def verify_qr_code(code)
    return false if qr_secret.blank? || code.blank?

    step_part, signature = code.to_s.split("-", 2)
    return false if signature.blank? || step_part !~ /\A\d+\z/

    step = step_part.to_i
    current_step = Time.current.to_i / QR_STEP_SECONDS
    return false if step > current_step

    expected = qr_signature(step)
    return false if expected.length != signature.length
    return false unless ActiveSupport::SecurityUtils.secure_compare(expected, signature)

    if step >= current_step - QR_GRACE_STEPS
      # Scanned while live: mark the code in use so it survives rotation
      # for the next QrScan::IN_USE_WINDOW.
      register_qr_scan(step)
      true
    else
      # Rotated out: only honor it if it was scanned while live and its
      # in-use window hasn't lapsed. Each use pushes the window out another
      # IN_USE_WINDOW so an in-progress checkout keeps the code alive.
      scan = qr_scans.in_use.find_by(step: step)
      return false unless scan

      scan.touch
      true
    end
  end

  def qr_seconds_remaining
    QR_STEP_SECONDS - (Time.current.to_i % QR_STEP_SECONDS)
  end

  def issue_qr_credentials
    self.qr_token ||= SecureRandom.urlsafe_base64(12)
    self.qr_secret ||= SecureRandom.hex(32)
  end

  private

  def qr_signature(step)
    OpenSSL::HMAC.hexdigest("sha256", qr_secret, "#{id}-#{step}")[0, 20]
  end

  def register_qr_scan(step)
    qr_scans.where("created_at < ?", 1.day.ago).delete_all
    scan = qr_scans.create_or_find_by!(step: step)
    # Repeat scans extend the in-use window to IN_USE_WINDOW from now.
    scan.touch unless scan.previously_new_record?
    scan
  end

  def requires_modempay_sync?
    modempay_sub_account_ready? &&
      (saved_change_to_settlement_code? || saved_change_to_settlement_account_number? ||
       saved_change_to_business_name?)
  end

  def sync_modempay_sub_account
    if modempay_sub_account_id.present?
      result = ModemPayService.update_sub_account(
        id: modempay_sub_account_id,
        percentage: MODEMPAY_BUSINESS_PERCENT,
        settlement_code: settlement_code,
        account_number: settlement_account_number
      )
    else
      result = ModemPayService.create_sub_account(
        business_name: business_name,
        percentage: MODEMPAY_BUSINESS_PERCENT,
        settlement_code: settlement_code,
        account_number: settlement_account_number
      )
    end

    if result.success?
      sub_account_id = result.payload["id"]
      update_column(:modempay_sub_account_id, sub_account_id) if sub_account_id.present?
    else
      Rails.logger.error "ModemPay sub-account sync failed for account #{id}: #{result.error}"
    end
  end
end
