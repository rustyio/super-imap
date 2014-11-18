class AddTypeToPartnerConnection < ActiveRecord::Migration
  def change
    add_column :partner_connections, :type, :string
  end
end
