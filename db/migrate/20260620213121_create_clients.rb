class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.string :email
      t.string :phone
      t.string :company
      t.text :address

      t.timestamps
    end
  end
end
