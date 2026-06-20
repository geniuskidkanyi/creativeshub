class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :business_name
      t.string :logo
      t.text :address
      t.string :phone
      t.string :website
      t.string :tax_id
      t.string :currency
      t.string :timezone

      t.timestamps
    end
  end
end
