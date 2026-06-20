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
    if amount < 5
      return redirect_to public_invoice_path(@invoice.public_token), alert: "Invoice amount must be at least D5."
    end

    method = params[:method] == "payment_session" ? "payment_session" : "payment_request"
    redirect_url = "#{Rails.configuration.x.public_host}/inv/#{@invoice.public_token}"
    client_ref = SecureRandom.urlsafe_base64(8)

    payment = @invoice.payments.create!(
      status: :pending,
      amount: @invoice.total_amount,
      currency: "GMD",
      payment_method: method
    )

    if method == "payment_session"
      result = WaychitService.create_payment_session(
        client_reference: payment.id.to_s,
        line_items: build_line_items,
        email: @invoice.client.email,
        return_url: redirect_url,
        metadata: { invoice_id: @invoice.id.to_s, invoice_number: @invoice.invoice_number }
      )
    else
      result = WaychitService.create_payment_request(
        amount: amount,
        client_reference: payment.id.to_s,
        description: "Invoice #{@invoice.invoice_number} - #{@invoice.client.name}",
        success_url: redirect_url,
        failure_url: redirect_url
      )
    end

    if result.success?
      payment.update!(waychit_id: result.payment_request_id || result.payment_session_id, metadata: result.raw_response)
      redirect_to result.launch_url, allow_other_host: true
    else
      payment.destroy
      Rails.logger.error "Waychit payment init failed: #{result.error}"
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

  def build_line_items
    @invoice.invoice_items.map do |item|
      line = {
        product_name: item.description,
        quantity: [ item.quantity.to_i, 1 ].max,
        price: item.unit_price.to_i
      }
      line
    end
  end
end
