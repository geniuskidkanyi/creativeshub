class Public::InvoicesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_account!

  before_action :set_invoice

  def show
  end

  def pay
    if @invoice.paid?
      return redirect_to public_invoice_path(@invoice.public_token), alert: "Invoice is already paid."
    end

    if @invoice.invoice_items.none?
      return redirect_to public_invoice_path(@invoice.public_token), alert: "This invoice has no line items."
    end

    @invoice.calculate_totals
    @invoice.save! if @invoice.changed?

    amount = @invoice.total_amount.to_i
    if amount < 1
      return redirect_to public_invoice_path(@invoice.public_token), alert: "Invoice amount must be at least D1."
    end

    redirect_url = "#{Rails.configuration.x.public_host}/inv/#{@invoice.public_token}"

    payment = @invoice.payments.create!(
      status: :pending,
      amount: @invoice.total_amount,
      currency: "GMD",
      payment_method: "payment_request"
    )

    result = ModemPayService.create_payment(
      amount: amount,
      currency: "GMD",
      description: "Invoice #{@invoice.invoice_number} - #{@invoice.client.name}",
      metadata: { payment_id: payment.id.to_s, invoice_id: @invoice.id.to_s, invoice_number: @invoice.invoice_number },
      return_url: redirect_url,
      cancel_url: redirect_url,
      sub_account: @account.modempay_sub_account_id.presence
    )

    if result.success?
      payment.update!(waychit_id: result.payment_intent_id, metadata: result.raw_response)
      redirect_to result.payment_link, allow_other_host: true
    else
      payment.destroy
      Rails.logger.error "ModemPay payment init failed: #{result.error}"
      redirect_to public_invoice_path(@invoice.public_token), alert: "Payment could not be initiated: #{result.error}"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Payment creation failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to public_invoice_path(@invoice.public_token), alert: "Payment could not be initiated. #{e.record.errors.full_messages.to_sentence}"
  end

  private

  def set_invoice
    @invoice = Invoice.find_by!(public_token: params[:token])
    @account = @invoice.account
  end
end
