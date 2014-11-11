class AddArchivedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :archived, :boolean, :default => false
  end
end
