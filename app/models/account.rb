class Account < ApplicationRecord
  has_one_attached :logo

  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :products, dependent: :destroy

  validates :business_name, presence: true

  after_commit :sync_modempay_sub_account, if: :requires_modempay_sync?

  MODEMPAY_PLATFORM_PERCENT = 1
  MODEMPAY_BUSINESS_PERCENT = 99

  def owner
    users.find_by(role: :owner)
  end

  def modempay_sub_account_ready?
    settlement_code.present? && settlement_account_number.present?
  end

  private

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
