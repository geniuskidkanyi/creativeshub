class AddDiscountToInvoicesAndRecurring < ActiveRecord::Migration[8.1]
  # A flat discount amount (in the invoice's currency) deducted from the
  # subtotal before tax. 0 = no discount.
  def change
    add_column :invoices, :discount, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :recurring_invoices, :discount, :decimal, precision: 12, scale: 2, null: false, default: 0
  end
end
