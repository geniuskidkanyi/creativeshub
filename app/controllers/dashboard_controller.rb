class DashboardController < ApplicationController
  def show
    @recent_invoices = current_account.invoices.ordered.limit(5)
    @invoice_count = current_account.invoices.count
    @paid_count = current_account.invoices.where(status: :paid).count
    @pending_count = current_account.invoices.where(status: [ :draft, :sent ]).count
    @overdue_count = current_account.invoices.where(status: [ :draft, :sent ]).where("due_date < ?", Date.current).count
    @total_revenue = current_account.invoices.where(status: :paid).sum(:total_amount)
    @unpaid_amount = current_account.invoices.where(status: [ :draft, :sent ]).sum(:total_amount)
    @client_count = current_account.clients.count
    @recent_payments = current_account.payments.succeeded.order(paid_at: :desc).limit(5)
    @monthly_revenue = current_account.invoices.where(status: :paid)
                                      .group_by_month(:paid_date, last: 12, current: true)
                                      .sum(:total_amount)
    @channel_totals = current_account.payments.succeeded.group(:payment_method).sum(:amount)
                                     .sort_by { |_, amount| -amount }
  end
end
