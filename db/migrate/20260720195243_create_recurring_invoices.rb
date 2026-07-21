class CreateRecurringInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_invoices do |t|
      t.references :account, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true

      t.string :title
      t.string :status, null: false, default: "active"

      # Schedule: every `interval` `frequency` starting `start_date`.
      t.string :frequency, null: false, default: "monthly"
      t.integer :interval, null: false, default: 1
      t.date :start_date, null: false
      t.date :end_date
      t.integer :max_occurrences

      # next_run_on is the scheduler's cursor — the generator job picks up
      # every active schedule whose cursor is due, so a missed day catches up
      # rather than silently skipping a cycle.
      t.date :next_run_on
      t.date :last_run_on
      t.integer :occurrences_count, null: false, default: 0

      t.integer :due_in_days, null: false, default: 14
      t.decimal :tax_rate, default: 0
      t.text :notes

      # When true the generated invoice is emailed to the client immediately
      # (only possible when the client has an email on file).
      t.boolean :auto_send, null: false, default: false

      t.timestamps
    end

    create_table :recurring_invoice_items do |t|
      t.references :recurring_invoice, null: false, foreign_key: true
      t.string :description
      t.decimal :quantity, default: 1
      t.decimal :unit_price
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :recurring_invoices, [ :status, :next_run_on ]

    add_reference :invoices, :recurring_invoice, foreign_key: true, index: true
  end
end
