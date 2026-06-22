class AddIndexOnConfirmationTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :confirmation_token, unique: true
  end
end
