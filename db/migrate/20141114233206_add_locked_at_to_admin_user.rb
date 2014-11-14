class AddLockedAtToAdminUser < ActiveRecord::Migration
  def change
    add_column :admin_users, :locked_at, :datetime
  end
end
