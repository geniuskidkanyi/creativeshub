class AddNoteToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :note, :string
  end
end
