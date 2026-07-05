class CreateQrScans < ActiveRecord::Migration[8.1]
  def change
    create_table :qr_scans do |t|
      t.references :account, null: false, foreign_key: true
      t.bigint :step, null: false

      t.timestamps
    end

    add_index :qr_scans, [ :account_id, :step ], unique: true
  end
end
