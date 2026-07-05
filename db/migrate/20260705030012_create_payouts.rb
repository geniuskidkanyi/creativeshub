class CreatePayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :payouts do |t|
      t.references :account, null: false, foreign_key: true
      t.decimal :amount, null: false
      t.decimal :fee
      t.string :currency, null: false, default: "GMD"
      t.string :network, null: false
      t.string :account_number, null: false
      t.string :beneficiary_name, null: false
      t.string :narration
      t.string :status, null: false, default: "pending"
      t.string :modempay_transfer_id
      t.string :transfer_reference
      t.string :idempotency_key, null: false
      t.text :error_message
      t.jsonb :webhook_data

      t.timestamps
    end

    add_index :payouts, :idempotency_key, unique: true
    add_index :payouts, :modempay_transfer_id
  end
end
