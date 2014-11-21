class AddRedirectUrlsToPartner < ActiveRecord::Migration
  def change
    add_column :partners, :success_url, :string
    add_column :partners, :failure_url, :string
  end
end
