class AddNameToPartnerConnection < ActiveRecord::Migration
  def change
    add_column :partner_connections, :name, :string
  end
end
