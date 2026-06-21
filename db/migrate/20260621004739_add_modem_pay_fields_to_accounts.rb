class AddModemPayFieldsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :modempay_sub_account_id, :string
    add_column :accounts, :settlement_code, :string
    add_column :accounts, :settlement_account_number, :string
  end
end
