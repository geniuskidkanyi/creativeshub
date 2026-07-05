class AddQrPaymentSupport < ActiveRecord::Migration[8.1]
  def up
    add_column :accounts, :qr_token, :string
    add_column :accounts, :qr_secret, :string
    add_index :accounts, :qr_token, unique: true

    # QR payments have no invoice, so payments now link to accounts directly.
    add_reference :payments, :account, foreign_key: true

    execute <<~SQL
      UPDATE payments
      SET account_id = invoices.account_id
      FROM invoices
      WHERE invoices.id = payments.invoice_id AND payments.account_id IS NULL
    SQL

    change_column_null :payments, :invoice_id, true

    Account.reset_column_information
    Account.find_each do |account|
      account.update_columns(
        qr_token: SecureRandom.urlsafe_base64(12),
        qr_secret: SecureRandom.hex(32)
      )
    end
  end

  def down
    remove_index :accounts, :qr_token
    remove_column :accounts, :qr_token
    remove_column :accounts, :qr_secret
    change_column_null :payments, :invoice_id, false
    remove_reference :payments, :account
  end
end
