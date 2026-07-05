# Production ran CreateQrScans while it was still the bare generator stub, so
# the table exists there without its columns. This migration is idempotent:
# it repairs a stub table and no-ops where the table is already correct.
class FixQrScansColumns < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:qr_scans)
      create_table :qr_scans do |t|
        t.references :account, null: false, foreign_key: true
        t.bigint :step, null: false
        t.timestamps
      end
      add_index :qr_scans, [ :account_id, :step ], unique: true
      return
    end

    # Rows are ephemeral scan markers — safe to clear before adding
    # NOT NULL columns.
    execute "DELETE FROM qr_scans"

    unless column_exists?(:qr_scans, :account_id)
      add_reference :qr_scans, :account, null: false, foreign_key: true
    end

    unless column_exists?(:qr_scans, :step)
      add_column :qr_scans, :step, :bigint, null: false
    end

    unless index_exists?(:qr_scans, [ :account_id, :step ], unique: true)
      add_index :qr_scans, [ :account_id, :step ], unique: true
    end
  end

  def down
    # Nothing to undo — this only repairs a malformed table.
  end
end
