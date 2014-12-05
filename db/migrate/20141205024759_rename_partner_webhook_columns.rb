class RenamePartnerWebhookColumns < ActiveRecord::Migration
  def change
    rename_column :partners, :success_webhook, :new_mail_webhook
    remove_column :partners, :failure_webhook
  end
end
