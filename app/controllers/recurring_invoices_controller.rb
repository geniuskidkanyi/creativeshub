class RecurringInvoicesController < ApplicationController
  before_action :set_recurring_invoice, only: [ :show, :edit, :update, :destroy, :pause, :resume, :generate_now ]

  def index
    @q = params[:q].to_s.strip
    scope = current_account.recurring_invoices.includes(:client, :recurring_invoice_items)
    scope = @q.present? ? scope.search_all(@q) : scope.ordered
    @pagy, @recurring_invoices = pagy(scope, limit: 20)
  end

  def show
    @invoices = @recurring_invoice.invoices.ordered.limit(50)
  end

  def new
    @recurring_invoice = current_account.recurring_invoices.new(start_date: Date.current, frequency: "monthly", interval: 1, currency: current_account.currency.presence || "GMD")
    @recurring_invoice.recurring_invoice_items.build
  end

  def create
    @recurring_invoice = current_account.recurring_invoices.new(recurring_invoice_params)

    if @recurring_invoice.save
      redirect_to @recurring_invoice, notice: "Recurring invoice scheduled."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @recurring_invoice.update(recurring_invoice_params)
      redirect_to @recurring_invoice, notice: "Schedule updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recurring_invoice.destroy
    redirect_to recurring_invoices_path, notice: "Schedule deleted. Invoices it already created are unaffected."
  end

  def pause
    @recurring_invoice.paused!
    redirect_to @recurring_invoice, notice: "Schedule paused."
  end

  def resume
    # A schedule paused for a while would otherwise fire every missed cycle at
    # once on resume; the cursor moves up to today so it restarts cleanly.
    @recurring_invoice.update!(status: :active, next_run_on: [ @recurring_invoice.next_run_on, Date.current ].compact.max)
    redirect_to @recurring_invoice, notice: "Schedule resumed. Next invoice #{@recurring_invoice.next_run_on.to_fs(:long)}."
  end

  def generate_now
    invoices = RecurringInvoiceGenerator.new(@recurring_invoice, on: Date.current).call

    if invoices.any?
      redirect_to @recurring_invoice, notice: "Generated #{invoices.size} invoice#{'s' if invoices.size != 1}."
    else
      redirect_to @recurring_invoice, alert: "Nothing due yet — next invoice is scheduled for #{@recurring_invoice.next_run_on&.to_fs(:long)}."
    end
  end

  private

  def set_recurring_invoice
    @recurring_invoice = current_account.recurring_invoices.find(params[:id])
  end

  def recurring_invoice_params
    params.require(:recurring_invoice).permit(
      :client_id, :title, :frequency, :interval, :start_date, :end_date, :max_occurrences,
      :due_in_days, :tax_rate, :notes, :auto_send, :currency, :fx_rate,
      recurring_invoice_items_attributes: [ :id, :description, :quantity, :unit_price, :position, :_destroy ]
    )
  end
end
