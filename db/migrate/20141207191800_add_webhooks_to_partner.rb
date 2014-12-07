class AddWebhooksToPartner < ActiveRecord::Migration
  def change
    add_column :partners, :user_connected_webhook, :string
    add_column :partners, :user_disconnected_webhook, :string
  end
end
