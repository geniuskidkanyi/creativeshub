class AddUuidToInvoices < ActiveRecord::Migration[8.1]
  # Detached from the app model so the migration stays valid as the app evolves.
  class MigrationInvoice < ActiveRecord::Base
    self.table_name = "invoices"
  end

  def up
    add_column :invoices, :uuid, :uuid

    MigrationInvoice.reset_column_information
    MigrationInvoice.where(uuid: nil).find_each do |invoice|
      invoice.update_columns(uuid: SecureRandom.uuid)
    end

    change_column_null :invoices, :uuid, false
    add_index :invoices, :uuid, unique: true
  end

  def down
    remove_column :invoices, :uuid
  end
end
