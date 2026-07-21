class AddCurrencyToInvoicesAndRecurringInvoices < ActiveRecord::Migration[8.1]
  def change
    # An invoice is denominated in `currency`; `fx_rate` is how many GMD one
    # unit of that currency is worth, captured at creation so the amount later
    # charged (always in GMD) is locked to the rate the invoice was issued at.
    # GMD invoices keep fx_rate 1.
    add_column :invoices, :currency, :string, null: false, default: "GMD"
    add_column :invoices, :fx_rate, :decimal, precision: 18, scale: 6, null: false, default: 1

    add_column :recurring_invoices, :currency, :string, null: false, default: "GMD"
    add_column :recurring_invoices, :fx_rate, :decimal, precision: 18, scale: 6, null: false, default: 1
  end
end
