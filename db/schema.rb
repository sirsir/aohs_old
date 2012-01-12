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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110704043313) do

  create_table "access_logs", :force => true do |t|
    t.datetime "last_access_time"
    t.string   "url"
    t.integer  "count"
    t.string   "login_name"
    t.string   "remote_ip"
    t.string   "mac_address"
  end

  create_table "call_bookmarks", :force => true do |t|
    t.integer  "voice_log_id", :limit => 8, :null => false
    t.integer  "start_msec"
    t.integer  "end_msec"
    t.string   "title"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "call_bookmarks", ["voice_log_id"], :name => "index_call_bookmarks_on_voice_log_id"

  create_table "call_informations", :force => true do |t|
    t.integer  "voice_log_id", :limit => 8, :null => false
    t.integer  "start_msec"
    t.integer  "end_msec"
    t.string   "event"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "agent_id"
  end

  add_index "call_informations", ["voice_log_id"], :name => "index_call_informations_on_voice_log_id"

  create_table "car_numbers", :force => true do |t|
    t.integer  "customer_id"
    t.string   "car_no",      :limit => 15
    t.string   "flag",        :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_numbers", ["customer_id"], :name => "cust_index1"

  create_table "computer_extension_maps", :force => true do |t|
    t.integer  "extension_id"
    t.string   "computer_name", :limit => 100
    t.string   "ip_address",    :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "computer_logs", :force => true do |t|
    t.datetime "check_time"
    t.string   "computer_name"
    t.string   "login_name"
    t.string   "os_version"
    t.string   "java_version"
    t.string   "watcher_version"
    t.string   "audioviewer_version"
    t.string   "cti_version"
    t.string   "versions"
    t.string   "remote_ip",           :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_datas", :force => true do |t|
    t.integer  "configuration_id"
    t.integer  "config_type"
    t.integer  "config_type_id"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "configuration_datas", ["configuration_id", "config_type"], :name => "index1"

  create_table "configuration_groups", :force => true do |t|
    t.string   "name",               :limit => 100
    t.string   "configuration_type", :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configurations", :force => true do |t|
    t.string   "variable"
    t.string   "default_value"
    t.string   "description"
    t.string   "variable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "configuration_group_id"
  end

  create_table "current_channel_status", :force => true do |t|
    t.integer  "system_id"
    t.integer  "device_id"
    t.integer  "channel_id"
    t.string   "ani",            :limit => 30
    t.string   "dnis",           :limit => 30
    t.string   "extension",      :limit => 15
    t.integer  "duration"
    t.datetime "start_time"
    t.integer  "hangup_cause"
    t.integer  "call_reference"
    t.integer  "agent_id",                      :default => 0
    t.string   "voice_file_url", :limit => 300
    t.string   "call_direction", :limit => 1,   :default => "u"
    t.string   "call_id",        :limit => 20
    t.integer  "site_id"
    t.string   "digest"
    t.string   "connected",      :limit => 15
  end

  create_table "current_computer_status", :force => true do |t|
    t.datetime "check_time"
    t.string   "computer_name"
    t.string   "login_name"
    t.string   "os_version"
    t.string   "java_version"
    t.string   "watcher_version"
    t.string   "audioviewer_version"
    t.string   "cti_version"
    t.string   "versions"
    t.string   "remote_ip",           :limit => 15
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "current_watcher_status", :force => true do |t|
    t.datetime "check_time"
    t.string   "agent_id"
    t.string   "extension"
    t.string   "extension2"
    t.string   "login_name"
    t.string   "remote_ip"
    t.string   "ctistatus"
  end

  create_table "customer_numbers", :force => true do |t|
    t.integer  "customer_id"
    t.string   "number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "customer_numbers", ["customer_id"], :name => "cust_index1"

  create_table "customers", :force => true do |t|
    t.string   "customer_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "flag"
  end

  add_index "customers", ["customer_name"], :name => "index_customers_on_customer_name"

  create_table "daily_statistics", :force => true do |t|
    t.date     "start_day",          :limit => 10, :null => false
    t.integer  "agent_id"
    t.integer  "keyword_id"
    t.integer  "statistics_type_id",               :null => false
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "daily_statistics", ["start_day", "agent_id", "statistics_type_id"], :name => "daily_index"
  add_index "daily_statistics", ["start_day", "keyword_id", "statistics_type_id"], :name => "daily_index2"

  create_table "did_agent_maps", :force => true do |t|
    t.string  "number",   :limit => 20
    t.integer "agent_id"
  end

  create_table "dids", :force => true do |t|
    t.string   "number",       :limit => 20
    t.integer  "extension_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dnis_agents", :force => true do |t|
    t.string   "dnis",       :limit => 10
    t.string   "ctilogin",   :limit => 50
    t.string   "team",       :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dsrresult_logs", :force => true do |t|
    t.integer  "voice_log_id", :limit => 8
    t.integer  "agent_id",     :limit => 8
    t.string   "server_name",  :limit => 21
    t.datetime "start_time"
    t.text     "result"
  end

  add_index "dsrresult_logs", ["voice_log_id"], :name => "index_dsrresult_logs_on_voice_log_id"

  create_table "edit_keywords", :force => true do |t|
    t.integer  "keyword_id",                     :null => false
    t.integer  "voice_log_id",                   :null => false
    t.integer  "start_msec"
    t.integer  "end_msec"
    t.integer  "result_keyword_id"
    t.integer  "user_id"
    t.string   "edit_status",       :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "edit_keywords", ["keyword_id", "voice_log_id"], :name => "indexkv"

  create_table "events", :force => true do |t|
    t.string   "name"
    t.string   "target"
    t.string   "status"
    t.datetime "start_time"
    t.datetime "complete_time"
    t.integer  "sevelity"
  end

  create_table "extension_to_agent_maps", :force => true do |t|
    t.string  "extension", :limit => 20
    t.integer "agent_id"
  end

  create_table "extensions", :force => true do |t|
    t.string   "number",     :limit => 20
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_categories", :force => true do |t|
    t.integer  "group_category_type_id", :default => 0, :null => false
    t.string   "value"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_categorizations", :force => true do |t|
    t.integer  "group_id",          :default => 0, :null => false
    t.integer  "group_category_id", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_category_display_trees", :force => true do |t|
    t.string   "group_category_type"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_category_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
  end

  create_table "group_managers", :force => true do |t|
    t.integer  "user_id"
    t.integer  "manager_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_members", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "leader_id",    :default => 0, :null => false
    t.integer  "lock_version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "job_schedulers", :force => true do |t|
    t.string   "name",       :limit => 50
    t.string   "parameters"
    t.string   "desc"
    t.datetime "updated_at"
    t.string   "state",      :limit => 20
  end

  create_table "keyword_group_maps", :force => true do |t|
    t.integer  "keyword_id",       :null => false
    t.integer  "keyword_group_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "keyword_group_maps", ["keyword_id", "keyword_group_id"], :name => "index1"

  create_table "keyword_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "keywords", :force => true do |t|
    t.string   "name"
    t.string   "keyword_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "deleted",      :default => false
    t.integer  "created_by"
    t.integer  "updated_by"
  end

  create_table "monthly_statistics", :force => true do |t|
    t.date     "start_day",          :limit => 10, :null => false
    t.integer  "agent_id"
    t.integer  "keyword_id"
    t.integer  "statistics_type_id",               :null => false
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "monthly_statistics", ["start_day", "agent_id", "statistics_type_id"], :name => "monthly_index"
  add_index "monthly_statistics", ["start_day", "keyword_id", "statistics_type_id"], :name => "monthly_index2"

  create_table "operation_logs", :force => true do |t|
    t.datetime "start_time"
    t.string   "name"
    t.string   "status"
    t.string   "target"
    t.string   "user"
    t.string   "remote_ip"
    t.string   "message"
    t.string   "application", :limit => 50
  end

  create_table "permissions", :force => true do |t|
    t.integer  "role_id"
    t.integer  "privilege_id"
    t.integer  "lock_version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "privileges", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "lock_version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "display_group"
    t.integer  "order_no"
    t.string   "application",   :limit => 50
  end

  create_table "result_keywords", :force => true do |t|
    t.integer  "start_msec"
    t.integer  "end_msec"
    t.integer  "voice_log_id", :limit => 8,                :null => false
    t.integer  "keyword_id",                :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "edit_status",  :limit => 1
  end

  add_index "result_keywords", ["keyword_id"], :name => "index_result_keywords_on_keyword_id"
  add_index "result_keywords", ["voice_log_id", "keyword_id"], :name => "rs_index1"
  add_index "result_keywords", ["voice_log_id"], :name => "index_result_keywords_on_voice_log_id"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "lock_version"
    t.integer  "order_no"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "statistics_types", :force => true do |t|
    t.string   "target_model"
    t.string   "value_type"
    t.boolean  "by_agent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tag_groups", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id",   :limit => 8, :null => false
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string  "name"
    t.integer "tag_group_id"
  end

  create_table "user_activity_logs", :force => true do |t|
    t.datetime "start_time"
    t.integer  "duration"
    t.string   "process_name"
    t.string   "window_title"
    t.string   "login_name"
    t.string   "remote_ip"
    t.string   "mac_address"
  end

  create_table "user_idle_logs", :force => true do |t|
    t.datetime "start_time"
    t.integer  "duration"
    t.string   "login_name"
    t.string   "remote_ip"
    t.string   "mac_address"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "state",                                   :default => "passive"
    t.datetime "deleted_at"
    t.string   "display_name"
    t.string   "type"
    t.integer  "group_id",                                :default => 0
    t.integer  "lock_version"
    t.integer  "role_id",                                 :default => 0,         :null => false
    t.string   "sex",                       :limit => 1,  :default => "u",       :null => false
    t.datetime "expired_date"
    t.boolean  "flag",                                    :default => false
    t.integer  "cti_agent_id"
    t.string   "id_card",                   :limit => 50
  end

  add_index "users", ["cti_agent_id"], :name => "index_users_on_cti_agent_id"

  create_table "voice_log_cars", :force => true do |t|
    t.integer "voice_log_id",  :limit => 8
    t.integer "car_number_id"
  end

  add_index "voice_log_cars", ["voice_log_id", "car_number_id"], :name => "vlcar_index"

  create_table "voice_log_counters", :force => true do |t|
    t.integer  "voice_log_id",        :limit => 8,                :null => false
    t.integer  "keyword_count",       :limit => 2, :default => 0
    t.integer  "ngword_count",        :limit => 2, :default => 0
    t.integer  "mustword_count",      :limit => 2, :default => 0
    t.integer  "bookmark_count",      :limit => 1, :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "transfer_call_count", :limit => 1, :default => 0
    t.integer  "transfer_in_count",   :limit => 1, :default => 0
    t.integer  "transfer_out_count",  :limit => 1, :default => 0
    t.integer  "transfer_duration",                :default => 0
    t.integer  "transfer_ng_count",   :limit => 2, :default => 0
    t.integer  "transfer_must_count", :limit => 2, :default => 0
  end

  add_index "voice_log_counters", ["voice_log_id"], :name => "index_voice_log_counters_on_voice_log_id"

  create_table "voice_log_customers", :force => true do |t|
    t.integer "voice_log_id", :limit => 8, :null => false
    t.integer "customer_id"
  end

  add_index "voice_log_customers", ["voice_log_id", "customer_id"], :name => "index1"

  create_table "voice_logs", :id => false, :force => true do |t|
    t.integer  "id",                  :limit => 8,                    :null => false
    t.integer  "system_id"
    t.integer  "device_id"
    t.integer  "channel_id"
    t.string   "ani",                 :limit => 30
    t.string   "dnis",                :limit => 30
    t.string   "extension",           :limit => 30
    t.integer  "duration",                           :default => 0
    t.integer  "hangup_cause"
    t.integer  "call_reference"
    t.integer  "agent_id",                           :default => 0
    t.string   "voice_file_url",      :limit => 300
    t.string   "call_direction",      :limit => 1,   :default => "u"
    t.datetime "start_time"
    t.string   "digest"
    t.string   "call_id"
    t.integer  "site_id"
    t.string   "ori_call_id",         :limit => 50
    t.string   "flag_tranfer",        :limit => 4
    t.string   "xfer_ani",            :limit => 45
    t.string   "xfer_dnis",           :limit => 45
    t.string   "log_trans_ani"
    t.string   "log_trans_dnis"
    t.string   "log_trans_extension"
  end

  add_index "voice_logs", ["ani"], :name => "index_voice_logs_on_ani"
  add_index "voice_logs", ["call_id"], :name => "index_voice_logs_on_call_id"
  add_index "voice_logs", ["dnis"], :name => "index_voice_logs_on_dnis"
  add_index "voice_logs", ["id"], :name => "index_id", :unique => true
  add_index "voice_logs", ["ori_call_id"], :name => "index_voice_logs_on_ori_call_id"
  add_index "voice_logs", ["start_time", "agent_id"], :name => "vc_index1"
  add_index "voice_logs", ["start_time"], :name => "index_voice_logs_on_start_time"

  create_table "voice_logs_201107", :force => true do |t|
    t.integer  "system_id"
    t.integer  "device_id"
    t.integer  "channel_id"
    t.string   "ani",                 :limit => 30
    t.string   "dnis",                :limit => 30
    t.string   "extension",           :limit => 30
    t.integer  "duration",                           :default => 0
    t.integer  "hangup_cause"
    t.integer  "call_reference"
    t.integer  "agent_id",                           :default => 0
    t.string   "voice_file_url",      :limit => 300
    t.string   "call_direction",      :limit => 1,   :default => "u"
    t.datetime "start_time"
    t.string   "digest"
    t.string   "call_id"
    t.integer  "site_id"
    t.string   "ori_call_id",         :limit => 50
    t.string   "flag_tranfer",        :limit => 4
    t.string   "xfer_ani",            :limit => 45
    t.string   "xfer_dnis",           :limit => 45
    t.string   "log_trans_ani"
    t.string   "log_trans_dnis"
    t.string   "log_trans_extension"
  end

  add_index "voice_logs_201107", ["ani"], :name => "index_voice_logs_on_ani"
  add_index "voice_logs_201107", ["call_id"], :name => "index_voice_logs_on_call_id"
  add_index "voice_logs_201107", ["dnis"], :name => "index_voice_logs_on_dnis"
  add_index "voice_logs_201107", ["ori_call_id"], :name => "index_voice_logs_on_ori_call_id"
  add_index "voice_logs_201107", ["start_time", "agent_id"], :name => "vc_index1"
  add_index "voice_logs_201107", ["start_time"], :name => "index_voice_logs_on_start_time"

  create_table "voice_logs_template", :force => true do |t|
    t.integer  "system_id"
    t.integer  "device_id"
    t.integer  "channel_id"
    t.string   "ani",                 :limit => 30
    t.string   "dnis",                :limit => 30
    t.string   "extension",           :limit => 30
    t.integer  "duration",                           :default => 0
    t.integer  "hangup_cause"
    t.integer  "call_reference"
    t.integer  "agent_id",                           :default => 0
    t.string   "voice_file_url",      :limit => 300
    t.string   "call_direction",      :limit => 1,   :default => "u"
    t.datetime "start_time"
    t.string   "digest"
    t.string   "call_id"
    t.integer  "site_id"
    t.string   "ori_call_id",         :limit => 50
    t.string   "flag_tranfer",        :limit => 4
    t.string   "xfer_ani",            :limit => 45
    t.string   "xfer_dnis",           :limit => 45
    t.string   "log_trans_ani"
    t.string   "log_trans_dnis"
    t.string   "log_trans_extension"
  end

  add_index "voice_logs_template", ["ani"], :name => "index_voice_logs_on_ani"
  add_index "voice_logs_template", ["call_id"], :name => "index_voice_logs_on_call_id"
  add_index "voice_logs_template", ["dnis"], :name => "index_voice_logs_on_dnis"
  add_index "voice_logs_template", ["ori_call_id"], :name => "index_voice_logs_on_ori_call_id"
  add_index "voice_logs_template", ["start_time", "agent_id"], :name => "vc_index1"
  add_index "voice_logs_template", ["start_time"], :name => "index_voice_logs_on_start_time"

  create_table "voice_logs_today", :force => true do |t|
    t.integer  "system_id"
    t.integer  "device_id"
    t.integer  "channel_id"
    t.string   "ani",                 :limit => 30
    t.string   "dnis",                :limit => 30
    t.string   "extension",           :limit => 30
    t.integer  "duration",                           :default => 0
    t.integer  "hangup_cause"
    t.integer  "call_reference"
    t.integer  "agent_id",                           :default => 0
    t.string   "voice_file_url",      :limit => 300
    t.string   "call_direction",      :limit => 1,   :default => "u"
    t.datetime "start_time"
    t.string   "digest"
    t.string   "call_id"
    t.integer  "site_id"
    t.string   "ori_call_id",         :limit => 50
    t.string   "flag_tranfer",        :limit => 4
    t.string   "xfer_ani",            :limit => 45
    t.string   "xfer_dnis",           :limit => 45
    t.string   "log_trans_ani"
    t.string   "log_trans_dnis"
    t.string   "log_trans_extension"
  end

  add_index "voice_logs_today", ["ani"], :name => "index_voice_logs_on_ani"
  add_index "voice_logs_today", ["call_id"], :name => "index_voice_logs_on_call_id"
  add_index "voice_logs_today", ["dnis"], :name => "index_voice_logs_on_dnis"
  add_index "voice_logs_today", ["ori_call_id"], :name => "index_voice_logs_on_ori_call_id"
  add_index "voice_logs_today", ["start_time", "agent_id"], :name => "vc_index1"
  add_index "voice_logs_today", ["start_time"], :name => "index_voice_logs_on_start_time"

  create_table "watcher_logs", :force => true do |t|
    t.datetime "check_time"
    t.string   "agent_id"
    t.string   "extension"
    t.string   "extension2"
    t.string   "login_name"
    t.string   "remote_ip"
    t.string   "ctistatus"
  end

  create_table "weekly_statistics", :force => true do |t|
    t.integer  "cweek"
    t.integer  "cwyear"
    t.date     "start_day",          :limit => 10, :null => false
    t.integer  "agent_id"
    t.integer  "keyword_id"
    t.integer  "statistics_type_id",               :null => false
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "weekly_statistics", ["start_day", "agent_id", "statistics_type_id"], :name => "weekly_index"
  add_index "weekly_statistics", ["start_day", "keyword_id", "statistics_type_id"], :name => "weekly_index2"

  create_table "xfer_logs", :force => true do |t|
    t.datetime "xfer_start_time"
    t.string   "xfer_ani",        :limit => 45
    t.string   "xfer_dnis",       :limit => 45
    t.string   "xfer_extension",  :limit => 45
    t.string   "xfer_call_id1",   :limit => 50
    t.string   "xfer_call_id2",   :limit => 50
    t.datetime "updated_on"
    t.string   "msg_type",        :limit => 10
    t.string   "xfer_type",       :limit => 20
    t.integer  "mapping_status",  :limit => 1
    t.string   "sender",          :limit => 10
    t.string   "ip",              :limit => 20
  end

end
