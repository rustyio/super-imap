# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141113190158) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "connection_types", force: true do |t|
    t.string   "auth_mechanism"
    t.string   "title"
    t.integer  "partner_connections_count"
    t.string   "host"
    t.integer  "port"
    t.boolean  "use_ssl"
    t.string   "oauth1_access_token_path"
    t.string   "oauth1_authorize_path"
    t.string   "oauth1_request_token_path"
    t.string   "oauth1_scope"
    t.string   "oauth1_site"
    t.string   "oauth2_grant_type"
    t.string   "oauth2_scope"
    t.string   "oauth2_site"
    t.string   "oauth2_token_method"
    t.string   "oauth2_token_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
  end

  create_table "imap_daemon_heartbeats", force: true do |t|
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mail_logs", force: true do |t|
    t.integer  "user_id"
    t.string   "md5",                 limit: 32
    t.string   "message_id"
    t.integer  "transmit_logs_count",            default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_logs", ["user_id"], name: "index_mail_logs_on_user_id", using: :btree

  create_table "partner_connections", force: true do |t|
    t.integer  "partner_id"
    t.integer  "connection_type_id"
    t.integer  "users_count",            default: 0
    t.string   "oauth1_consumer_key"
    t.string   "oauth1_consumer_secret"
    t.string   "oauth2_client_id"
    t.string   "oauth2_client_secret"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "partner_connections", ["connection_type_id"], name: "index_partner_connections_on_connection_type_id", using: :btree
  add_index "partner_connections", ["partner_id"], name: "index_partner_connections_on_partner_id", using: :btree

  create_table "partners", force: true do |t|
    t.string   "api_key"
    t.string   "name"
    t.string   "success_webhook"
    t.string   "failure_webhook"
    t.integer  "partner_connections_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transmit_logs", force: true do |t|
    t.integer  "mail_log_id"
    t.integer  "response_code"
    t.string   "response_body", limit: 1024
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transmit_logs", ["mail_log_id"], name: "index_transmit_logs_on_mail_log_id", using: :btree

  create_table "users", force: true do |t|
    t.integer  "partner_connection_id"
    t.string   "email"
    t.string   "tag"
    t.integer  "mail_logs_count",       default: 0
    t.datetime "last_connected_at"
    t.datetime "last_email_at"
    t.integer  "last_uid"
    t.string   "last_uid_validity"
    t.datetime "last_internal_date"
    t.string   "login_username"
    t.string   "login_password"
    t.string   "oauth1_token"
    t.string   "oauth1_token_secret"
    t.string   "oauth2_refresh_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "archived",              default: false
    t.string   "type"
  end

  add_index "users", ["partner_connection_id"], name: "index_users_on_partner_connection_id", using: :btree

end
