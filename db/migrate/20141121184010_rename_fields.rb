class RenameFields < ActiveRecord::Migration
  def change
    remove_column :users, :last_connected_at, :datetime
    add_column :users, :connected_at, :datetime
    add_column :users, :last_login_at, :datetime
    remove_column :mail_logs, :md5, :string
    add_column :mail_logs, :sha1, :string, :limit => 40, :index => true
  end
end
