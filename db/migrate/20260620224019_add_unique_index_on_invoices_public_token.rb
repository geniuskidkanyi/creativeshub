class AddUniqueIndexOnInvoicesPublicToken < ActiveRecord::Migration[8.1]
  def change
    add_index :invoices, :public_token, unique: true
  end
end
