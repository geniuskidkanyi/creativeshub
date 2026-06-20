class AddPublicTokenToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :public_token, :string
  end
end
