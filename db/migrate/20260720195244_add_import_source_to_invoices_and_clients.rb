class AddImportSourceToInvoicesAndClients < ActiveRecord::Migration[8.1]
  def change
    # external_ref carries the identifier the record had in the system it came
    # from (Wave's customer name, or its invoice number). Paired with a unique
    # index it makes re-running an import idempotent: a second upload of the
    # same export updates the existing rows instead of duplicating them.
    add_column :clients, :external_source, :string
    add_column :clients, :external_ref, :string
    add_column :invoices, :external_source, :string
    add_column :invoices, :external_ref, :string

    add_index :clients, [ :account_id, :external_source, :external_ref ],
              unique: true, where: "external_ref IS NOT NULL", name: "index_clients_on_external_ref"
    add_index :invoices, [ :account_id, :external_source, :external_ref ],
              unique: true, where: "external_ref IS NOT NULL", name: "index_invoices_on_external_ref"
  end
end
