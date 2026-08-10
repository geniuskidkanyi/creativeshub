# Security alert: the wallet/account that payouts are sent to was changed.
# Always notify so a fraudulent change can't happen silently.
class SettlementChangedNotifier < ApplicationNotifier
  required_param :account

  def account = params[:account]

  def title = "Payout destination changed"

  def message(_notification = nil)
    "Your payout wallet was updated to #{params[:network].to_s.titleize} #{params[:account_number]}. " \
      "If this wasn't you, secure your account immediately."
  end

  def url(_notification = nil) = Rails.application.routes.url_helpers.edit_account_path

  def icon = "alert"
  def category = "security"
end
