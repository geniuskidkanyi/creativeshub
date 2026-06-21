class SyncModemPaySubAccountJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return unless account&.modempay_sub_account_ready?

    if account.modempay_sub_account_id.present?
      result = ModemPayService.update_sub_account(
        id: account.modempay_sub_account_id,
        business_name: account.business_name,
        percentage: Account::MODEMPAY_BUSINESS_PERCENT,
        settlement_code: account.settlement_code,
        account_number: account.settlement_account_number
      )
    else
      result = ModemPayService.create_sub_account(
        business_name: account.business_name,
        percentage: Account::MODEMPAY_BUSINESS_PERCENT,
        settlement_code: account.settlement_code,
        account_number: account.settlement_account_number
      )
    end

    if result.success?
      sub_account_id = result.payload["id"]
      account.update_column(:modempay_sub_account_id, sub_account_id) if sub_account_id.present?
    else
      Rails.logger.error "ModemPay sub-account sync failed for account #{account_id}: #{result.error}"
    end
  end
end
