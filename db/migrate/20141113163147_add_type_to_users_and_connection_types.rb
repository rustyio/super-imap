class AddTypeToUsersAndConnectionTypes < ActiveRecord::Migration
  def change
    add_column :connection_types, :type, :string
    add_column :users, :type, :string
  end
end
