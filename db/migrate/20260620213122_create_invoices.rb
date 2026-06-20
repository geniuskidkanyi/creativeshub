class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :invoice_number
      t.string :status
      t.date :issue_date
      t.date :due_date
      t.decimal :subtotal
      t.decimal :tax_rate
      t.decimal :tax_amount
      t.decimal :total_amount
      t.text :notes
      t.datetime :paid_date
      t.string :payment_method

      t.timestamps
    end
  end
end
