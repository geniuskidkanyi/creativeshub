class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :waychit_id
      t.string :status
      t.decimal :amount
      t.string :currency
      t.string :payment_method
      t.string :client_reference
      t.string :transaction_reference
      t.jsonb :metadata
      t.datetime :paid_at
      t.jsonb :webhook_data

      t.timestamps
    end
  end
end
