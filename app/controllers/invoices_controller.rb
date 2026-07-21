class InvoicesController < ApplicationController
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :pay, :send_invoice ]

  def index
    @q = params[:q].to_s.strip
    # search_all already joins clients; only eager-load on the unfiltered list.
    scope = @q.present? ? current_account.invoices.search_all(@q) : current_account.invoices.includes(:client).ordered
    @pagy, @invoices = pagy(scope, limit: 20)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: @invoice.invoice_number || "invoice",
               template: "invoices/show",
               layout: "pdf",
               page_size: "A4",
               disposition: "attachment"
      end
    end
  end

  def new
    @invoice = current_account.invoices.new(status: :sent, currency: current_account.currency.presence || "GMD")
    @invoice.invoice_items.build
    @clients = current_account.clients.ordered
  end

  def create
    @invoice = current_account.invoices.new(invoice_params)
    # A generated invoice is immediately live ("sent") — no draft stage.
    @invoice.status = :sent
    @invoice.issue_date ||= Date.current

    if @invoice.save
      redirect_to @invoice, notice: "Invoice was successfully created."
    else
      @clients = current_account.clients.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = current_account.clients.ordered
  end

  def update
    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: "Invoice was successfully updated."
    else
      @clients = current_account.clients.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: "Invoice was successfully deleted."
  end

  def send_invoice
    @invoice.mark_as_sent!

    # Clients imported from other tools often have no email on file. Marking
    # sent still works — the invoice is shared by its public link instead.
    unless @invoice.client.emailable?
      return redirect_to @invoice, notice: "Invoice marked as sent. #{@invoice.client.name} has no email on file — share the payment link instead."
    end

    InvoiceMailer.send_invoice(@invoice).deliver_later
    redirect_to @invoice, notice: "Invoice marked as sent and emailed to client."
  end

  def pay
    if @invoice.paid?
      return redirect_to @invoice, alert: "Invoice is already paid."
    end

    if @invoice.invoice_items.none?
      return redirect_to @invoice, alert: "Add line items before accepting payment."
    end

    @invoice.calculate_totals
    @invoice.save! if @invoice.changed?

    # The customer is always charged in GMD so settlement lands in the account's
    # GMD balance; for a foreign-currency invoice that's the total converted at
    # the invoice's locked fx_rate.
    amount = @invoice.gmd_total.to_i
    if amount < 1
      return redirect_to @invoice, alert: "Invoice amount must be at least D1."
    end

    redirect_url = "#{Rails.configuration.x.public_host}/inv/#{@invoice.public_token}"

    payment = @invoice.payments.create!(
      status: :pending,
      amount: @invoice.gmd_total,
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
      sub_account: current_account.modempay_sub_account_id.presence
    )

    if result.success?
      payment.update!(waychit_id: result.payment_intent_id, metadata: result.raw_response)
      redirect_to result.payment_link, allow_other_host: true
    else
      payment.destroy
      Rails.logger.error "ModemPay payment init failed: #{result.error}"
      redirect_to @invoice, alert: "Payment could not be initiated: #{result.error}"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Payment creation failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to @invoice, alert: "Payment could not be initiated. #{e.record.errors.full_messages.to_sentence}"
  end

  private

  def set_invoice
    @invoice = current_account.invoices.find_by!(uuid: params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :client_id, :status, :issue_date, :due_date, :tax_rate, :notes, :currency, :fx_rate,
      invoice_items_attributes: [ :id, :description, :quantity, :unit_price, :_destroy ]
    )
  end
end
