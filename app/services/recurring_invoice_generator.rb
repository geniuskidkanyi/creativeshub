# Turns a due recurring schedule into a real invoice.
#
# Catches up rather than skipping: if the worker was down for a week, a weekly
# schedule generates the invoices it missed, each dated to the cycle it belongs
# to, instead of collapsing them into one. The cursor advances after each, so a
# crash mid-catch-up resumes where it stopped rather than double-billing.
class RecurringInvoiceGenerator
  MAX_CATCHUP = 24

  def initialize(recurring_invoice, on: Date.current)
    @schedule = recurring_invoice
    @on = on
  end

  def call
    generated = []

    MAX_CATCHUP.times do
      break unless due?
      issue_on = @schedule.next_run_on
      invoice = build_invoice(issue_on)

      RecurringInvoice.transaction do
        invoice.save!
        @schedule.advance_cursor!(issue_on)
      end

      deliver(invoice)
      generated << invoice
    end

    generated
  end

  private

  def due?
    @schedule.active? && @schedule.next_run_on.present? && @schedule.next_run_on <= @on && !@schedule.finished?(@schedule.next_run_on)
  end

  def build_invoice(issue_on)
    invoice = @schedule.account.invoices.new(
      client: @schedule.client,
      recurring_invoice: @schedule,
      issue_date: issue_on,
      due_date: issue_on + @schedule.due_in_days.days,
      tax_rate: @schedule.tax_rate,
      discount: @schedule.discount,
      currency: @schedule.currency,
      fx_rate: @schedule.fx_rate,
      notes: @schedule.notes,
      status: :sent
    )

    @schedule.recurring_invoice_items.each do |item|
      invoice.invoice_items.new(item.to_invoice_item_attributes)
    end

    invoice
  end

  # A schedule can outlive the client's email being on file, so auto-send is
  # best-effort: the invoice still exists and can be shared by link.
  def deliver(invoice)
    return unless @schedule.auto_send && invoice.client.emailable?

    InvoiceMailer.send_invoice(invoice).deliver_later
  rescue StandardError => e
    Rails.logger.error "Recurring invoice #{invoice.id} auto-send failed: #{e.message}"
  end
end
