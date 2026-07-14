class AddAdminToUsers < ActiveRecord::Migration[8.1]
  def change
    # Platform-level admin (Avo access). Named platform_admin because
    # users.role is an enum whose "admin" value already defines User#admin?
    # (account-level admin) — this flag must never be confused with that.
    add_column :users, :platform_admin, :boolean, default: false, null: false
  end
end
