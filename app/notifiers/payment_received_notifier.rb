# Fires when a customer's payment succeeds — the notification the business
# owner most wants. Covers both invoice payments and anonymous QR payments.
class PaymentReceivedNotifier < ApplicationNotifier
  required_param :payment

  def payment = params[:payment]

  def title = "Payment received"

  def message(_notification = nil)
    who = payment.payer_label
    "You received #{amount} from #{who}."
  end

  def url(_notification = nil)
    payment.invoice ? Rails.application.routes.url_helpers.invoice_path(payment.invoice) : "/dashboard"
  end

  def amount
    "D#{ActiveSupport::NumberHelper.number_to_delimited(payment.amount.to_i)}"
  end

  def icon = "cash"
  def category = "payment"
end
