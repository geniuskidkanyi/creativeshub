class GenerateRecurringInvoicesJob < ApplicationJob
  queue_as :default

  # Runs daily. Each schedule is isolated so one bad schedule (a deleted
  # client, an invalid line) cannot stop the rest of the account's billing.
  def perform(on: Date.current)
    RecurringInvoice.due(on).includes(:client, :recurring_invoice_items).find_each do |schedule|
      invoices = RecurringInvoiceGenerator.new(schedule, on: on).call
      Rails.logger.info "Recurring schedule #{schedule.id}: generated #{invoices.size} invoice(s)" if invoices.any?
    rescue StandardError => e
      Rails.logger.error "Recurring schedule #{schedule.id} failed: #{e.class}: #{e.message}"
    end
  end
end
