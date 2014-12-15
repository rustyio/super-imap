class AddTracerToUsers < ActiveRecord::Migration
  def change
    add_column :users, :enable_tracer, :boolean, :default => false
    # add_index :users, :enable_tracer
  end
end
