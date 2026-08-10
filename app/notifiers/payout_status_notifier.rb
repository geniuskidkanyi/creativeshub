# Fires when a payout's status settles (completed / failed / flagged) — the
# outcome of money leaving the account, which today has no owner-facing signal.
class PayoutStatusNotifier < ApplicationNotifier
  required_param :payout

  def payout = params[:payout]

  def title
    case payout.status
    when "completed" then "Payout completed"
    when "failed" then "Payout failed"
    when "flagged" then "Payout under review"
    else "Payout update"
    end
  end

  def message(_notification = nil)
    dest = "#{payout.network.titleize} #{payout.account_number}"
    case payout.status
    when "completed" then "Your payout of #{amount} to #{dest} completed."
    when "failed" then "Your payout of #{amount} to #{dest} failed. The funds remain in your balance.#{error_suffix}"
    when "flagged" then "Your payout of #{amount} to #{dest} is being reviewed and hasn't been released yet."
    else "Payout of #{amount} to #{dest}: #{payout.status}."
    end
  end

  def url(_notification = nil) = Rails.application.routes.url_helpers.payouts_path

  def amount = "D#{ActiveSupport::NumberHelper.number_to_delimited(payout.amount.to_i)}"

  def icon = payout.completed? ? "cash" : "alert"
  def category = payout.failed? || payout.flagged? ? "alert" : "payout"

  private

  def error_suffix
    payout.error_message.present? ? " (#{payout.error_message})" : ""
  end
end
