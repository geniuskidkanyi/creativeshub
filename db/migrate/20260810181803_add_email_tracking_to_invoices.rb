class AddEmailTrackingToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :email_sent_at, :datetime
    add_column :invoices, :email_opened_at, :datetime
    add_column :invoices, :email_opens, :integer, null: false, default: 0
  end
end
