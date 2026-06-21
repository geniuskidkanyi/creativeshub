class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.decimal :unit_price

      t.timestamps
    end
  end
end
