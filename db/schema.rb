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

ActiveRecord::Schema.define(version: 20180503022144) do

  create_table "analytic_patterns", force: :cascade do |t|
    t.integer  "analytic_template_id", limit: 4,     null: false
    t.text     "pattern",              limit: 65535
    t.string   "pattern_type",         limit: 255
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "analytic_template_maps", force: :cascade do |t|
    t.integer  "template_id",       limit: 4
    t.integer  "template_child_id", limit: 4
    t.integer  "order_no",          limit: 4
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "analytic_templates", force: :cascade do |t|
    t.string   "title",        limit: 200
    t.string   "speaker_type", limit: 1,   default: "", null: false
    t.string   "flag",         limit: 1,   default: "", null: false
    t.string   "match_range",  limit: 255
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "evaluation_criteria", force: :cascade do |t|
    t.integer  "evaluation_plan_id",     limit: 4,                null: false, index: {name: "index_eplan", using: :btree}
    t.string   "name",                   limit: 255,              null: false
    t.string   "item_type",              limit: 30,               null: false
    t.string   "flag",                   limit: 1,   default: "", null: false
    t.integer  "order_no",               limit: 4,   default: 0,  null: false
    t.integer  "parent_id",              limit: 4,   default: 0,  null: false
    t.float    "weighted_score",         limit: 24
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "variable_name",          limit: 80
    t.integer  "evaluation_question_id", limit: 4
    t.integer  "revision_no",            limit: 4
    t.integer  "question_group_id",      limit: 4
  end

  create_table "evaluation_plans", force: :cascade do |t|
    t.string   "name",                        limit: 120,                null: false, index: {name: "index_evaluation_plans_on_name", using: :btree}
    t.string   "description",                 limit: 255
    t.string   "flag",                        limit: 1,     default: "", null: false
    t.integer  "revision_no",                 limit: 4,                  null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "evaluation_grade_setting_id", limit: 4, index: {name: "fk_evaluation_plans_evaluation_grade_setting_id", using: :btree}
    t.text     "rules",                       limit: 65535
    t.text     "call_settings",               limit: 65535
    t.string   "asst_flag",                   limit: 3
    t.integer  "order_no",                    limit: 4
    t.string   "show_group_flag",             limit: 1
    t.string   "comment_flag",                limit: 3
  end

  create_view "auto_assessment_criteria", <<-'END_VIEW_AUTO_ASSESSMENT_CRITERIA', :force => true
select `p`.`id` AS `evaluation_plan_id`,`p`.`revision_no` AS `revision_no`,`c`.`evaluation_question_id` AS `evaluation_question_id`,`c`.`question_group_id` AS `question_group_id`,`c`.`name` AS `name` from (`evaluation_plans` `p` join `evaluation_criteria` `c` on(((`p`.`id` = `c`.`evaluation_plan_id`) and (`p`.`revision_no` = `c`.`revision_no`)))) where ((`c`.`item_type` = 'criteria') and (`p`.`flag` <> 'D')) order by `p`.`id`,`p`.`revision_no`,`c`.`order_no`
  END_VIEW_AUTO_ASSESSMENT_CRITERIA

  create_table "auto_assessment_logs", force: :cascade do |t|
    t.integer  "voice_log_id",           limit: 8,        null: false, index: {name: "index_voice_log", using: :btree}
    t.integer  "evaluation_plan_id",     limit: 4
    t.integer  "evaluation_question_id", limit: 4
    t.integer  "evaluation_answer_id",   limit: 4
    t.string   "result",                 limit: 50
    t.text     "result_log",             limit: 16777215
    t.string   "flag",                   limit: 1
    t.datetime "created_at"
  end

  create_table "auto_assessment_rules", force: :cascade do |t|
    t.string   "name",         limit: 100
    t.string   "display_name", limit: 100
    t.string   "rule_type",    limit: 100
    t.text     "rule_options", limit: 16777215
    t.string   "flag",         limit: 3
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "auto_assessment_settings", force: :cascade do |t|
    t.integer  "evaluation_plan_id", limit: 4,     default: 0,  null: false
    t.text     "setting_string",     limit: 65535
    t.string   "flag",               limit: 1,     default: "", null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "call_annotations", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8,                null: false, index: {name: "index_vl", using: :btree}
    t.string   "annot_type",   limit: 10,  default: "", null: false
    t.integer  "start_msec",   limit: 4
    t.integer  "end_msec",     limit: 4
    t.string   "title",        limit: 150
    t.datetime "start_time"
    t.datetime "end_time"
  end

  create_table "call_categories", force: :cascade do |t|
    t.string   "title",         limit: 100,              null: false
    t.string   "code_name",     limit: 100
    t.string   "flag",          limit: 1,   default: "", null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "category_type", limit: 100
    t.string   "alias_name",    limit: 200
    t.string   "fg_color",      limit: 15
    t.string   "bg_color",      limit: 15
    t.integer  "order_no",      limit: 4
  end

  create_table "call_category_types", force: :cascade do |t|
    t.string  "title",     limit: 100, null: false
    t.integer "order_no",  limit: 4
    t.integer "parent_id", limit: 4
  end

  create_table "call_classifications", force: :cascade do |t|
    t.integer  "voice_log_id",     limit: 8,              null: false, index: {name: "index_vl", using: :btree}
    t.integer  "call_category_id", limit: 4,              null: false, index: {name: "index_call_cate", using: :btree}
    t.string   "flag",             limit: 1, default: "", null: false
    t.datetime "updated_at"
    t.integer  "updated_by",       limit: 4
  end
  add_index "call_classifications", ["voice_log_id", "call_category_id"], name: "index_vl_ca", using: :btree

  create_table "call_comments", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8,                  null: false, index: {name: "index_call_comments_on_voice_log_id", using: :btree}
    t.integer  "start_sec",    limit: 4
    t.integer  "end_sec",      limit: 4
    t.text     "comment",      limit: 65535
    t.integer  "created_by",   limit: 4
    t.string   "flag",         limit: 1,     default: "", null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "call_customers", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8, null: false, index: {name: "index_vl", using: :btree}
    t.integer  "customer_id",  limit: 4, null: false
    t.datetime "updated_at"
  end

  create_table "call_emotions", force: :cascade do |t|
    t.integer "voice_log_id",  limit: 8,             null: false, index: {name: "index_voice_id", unique: true, using: :btree}
    t.integer "emotion_score", limit: 4, default: 0, null: false
  end

  create_table "call_favourites", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8, null: false, index: {name: "index_vl", using: :btree}
    t.integer  "user_id",      limit: 4, null: false
    t.datetime "created_at"
  end
  add_index "call_favourites", ["voice_log_id", "user_id"], name: "index_vl_usr", using: :btree

  create_table "call_informations", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8,              null: false, index: {name: "index_vl", using: :btree}
    t.integer  "start_msec",   limit: 4,  default: 0
    t.integer  "end_msec",     limit: 4,  default: 0
    t.datetime "start_time",   index: {name: "index_vl_stime", using: :btree}
    t.datetime "end_time"
    t.string   "event",        limit: 40
    t.integer  "agent_id",     limit: 4,  default: 0
    t.string   "number1",      limit: 50
    t.string   "number2",      limit: 50
    t.string   "extension",    limit: 50
    t.string   "call_id",      limit: 45
    t.string   "is_transfer",  limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "call_reasons", force: :cascade do |t|
    t.integer "voice_log_id", limit: 8,   null: false, index: {name: "index_vl", using: :btree}
    t.integer "reason_id",    limit: 4
    t.string  "title",        limit: 255
  end

  create_table "call_statistics", force: :cascade do |t|
    t.integer  "stats_date_id", limit: 4,             null: false, index: {name: "index_d_report2", with: ["stats_type"], using: :btree}
    t.integer  "agent_id",      limit: 4,             null: false
    t.integer  "stats_type",    limit: 4,             null: false, index: {name: "index_d_report", with: ["agent_id", "stats_date_id"], using: :btree}
    t.integer  "total",         limit: 4, default: 0
    t.datetime "updated_at"
    t.integer  "group_id",      limit: 4
  end
  add_index "call_statistics", ["stats_type", "stats_date_id"], name: "index_d_report3", using: :btree

  create_table "call_tracking_logs", force: :cascade do |t|
    t.integer  "tracking_type", limit: 4,   null: false
    t.integer  "user_id",       limit: 4,   null: false
    t.integer  "voice_log_id",  limit: 8,   null: false, index: {name: "index_vl", using: :btree}
    t.integer  "listened_sec",  limit: 4
    t.string   "request_id",    limit: 100
    t.string   "session_id",    limit: 100
    t.string   "remote_ip",     limit: 20
    t.datetime "created_at",    index: {name: "index_crtd", using: :btree}
  end

  create_table "call_transcriptions", force: :cascade do |t|
    t.integer "voice_log_id", limit: 8,               null: false, index: {name: "index_vl", using: :btree}
    t.integer "speaker_id",   limit: 4
    t.string  "speaker_type", limit: 255,             null: false
    t.integer "channel",      limit: 4,   default: 0, null: false
    t.integer "start_msec",   limit: 4
    t.integer "end_msec",     limit: 4
    t.string  "result",       limit: 300,             null: false
  end

  create_table "computer_infos", force: :cascade do |t|
    t.string   "computer_name", limit: 100, null: false, index: {name: "index_compname", using: :btree}
    t.string   "ip_address",    limit: 50,  null: false, index: {name: "index_computer_infos_on_ip_address", using: :btree}
    t.integer  "extension_id",  limit: 4, index: {name: "index_computer_infos_on_extension_id", using: :btree}
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end
  add_index "computer_infos", ["ip_address"], name: "index_ip", using: :btree

  create_table "computer_logs", id: false, force: :cascade do |t|
    t.datetime "check_time",          index: {name: "index_computer_logs_on_check_time", using: :btree}
    t.string   "computer_name",       limit: 60
    t.string   "login_name",          limit: 60, index: {name: "index_computer_logs_on_login_name_and_check_time", with: ["check_time"], using: :btree}
    t.string   "os_version",          limit: 30
    t.string   "java_version",        limit: 30
    t.string   "watcher_version",     limit: 30
    t.string   "audioviewer_version", limit: 30
    t.string   "cti_version",         limit: 30
    t.string   "remote_ip",           limit: 50, index: {name: "index_computer_logs_on_remote_ip_and_check_time", with: ["check_time"], using: :btree}
    t.string   "computer_event",      limit: 20
    t.datetime "created_at"
    t.string   "domain_name",         limit: 100
  end

  create_table "configuration_details", force: :cascade do |t|
    t.integer  "configuration_id",      limit: 4,   null: false, index: {name: "index_id_tree", with: ["configuration_tree_id"], using: :btree}
    t.integer  "configuration_tree_id", limit: 4,   null: false
    t.string   "conf_value",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_groups", force: :cascade do |t|
    t.string   "name",       limit: 80,               null: false, index: {name: "index_configuration_groups_on_name", unique: true, using: :btree}
    t.string   "desc",       limit: 255, default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configuration_trees", force: :cascade do |t|
    t.integer "node_id",                limit: 4,              null: false, index: {name: "index_id_node_type", with: ["node_type"], using: :btree}
    t.string  "node_type",              limit: 30,             null: false
    t.integer "parent_id",              limit: 4,  default: 0, index: {name: "index_configuration_trees_on_parent_id", using: :btree}
    t.integer "configuration_group_id", limit: 4
  end

  create_table "configurations", force: :cascade do |t|
    t.string  "variable",               limit: 80,                     null: false
    t.string  "desc",                   limit: 255, default: ""
    t.string  "value_type",             limit: 100, default: "string", null: false
    t.integer "configuration_group_id", limit: 4, index: {name: "index_group", using: :btree}
  end
  add_index "configurations", ["configuration_group_id", "variable"], name: "index_group_var", unique: true, using: :btree

  create_table "current_channel_status", force: :cascade do |t|
    t.integer  "site_id",        limit: 3
    t.integer  "system_id",      limit: 3
    t.integer  "device_id",      limit: 4
    t.integer  "channel_id",     limit: 4
    t.string   "ani",            limit: 50,  default: ""
    t.string   "dnis",           limit: 50,  default: ""
    t.string   "extension",      limit: 10,  default: ""
    t.integer  "duration",       limit: 4
    t.integer  "hangup_cause",   limit: 4
    t.integer  "call_reference", limit: 4
    t.integer  "agent_id",       limit: 4
    t.string   "voice_file_url", limit: 200, default: ""
    t.string   "call_direction", limit: 1,   default: ""
    t.datetime "start_time"
    t.string   "call_id",        limit: 45, index: {name: "index_call_id", using: :btree}
    t.string   "ori_call_id",    limit: 50
    t.datetime "answer_time"
    t.string   "flag",           limit: 3,   default: ""
    t.string   "connected",      limit: 20
  end
  add_index "current_channel_status", ["id"], name: "index_id", using: :btree

  create_table "current_computer_status", id: false, force: :cascade do |t|
    t.datetime "check_time",          index: {name: "index_computer_logs_on_check_time", using: :hash}
    t.string   "computer_name",       limit: 60
    t.string   "login_name",          limit: 60, index: {name: "index_computer_logs_on_login_name_and_check_time", with: ["check_time"], using: :hash}
    t.string   "os_version",          limit: 30
    t.string   "java_version",        limit: 30
    t.string   "watcher_version",     limit: 30
    t.string   "audioviewer_version", limit: 30
    t.string   "cti_version",         limit: 30
    t.string   "remote_ip",           limit: 50, index: {name: "index_computer_logs_on_remote_ip_and_check_time", with: ["check_time"], using: :hash}
    t.string   "computer_event",      limit: 20
    t.datetime "created_at"
    t.string   "domain_name",         limit: 50
  end

  create_table "dids", force: :cascade do |t|
    t.string   "number",       limit: 20, null: false, index: {name: "index_dids_on_number", using: :btree}
    t.integer  "extension_id", limit: 4,  null: false, index: {name: "index_dids_on_extension_id", using: :btree}
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "extensions", force: :cascade do |t|
    t.string   "number",      limit: 10, null: false, index: {name: "index_extensions_on_number", unique: true, using: :btree}
    t.integer  "user_id",     limit: 4
    t.integer  "location_id", limit: 4
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "user_extension_maps", force: :cascade do |t|
    t.string   "extension",  limit: 15, index: {name: "index_user_extension_maps_on_extension", using: :btree}
    t.string   "did",        limit: 20, index: {name: "index_user_extension_maps_on_did", using: :btree}
    t.integer  "agent_id",   limit: 4,  null: false
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",                  limit: 50,                null: false, index: {name: "index_users_on_login", unique: true, using: :btree}
    t.integer  "title_id",               limit: 4
    t.string   "full_name_en",           limit: 255, default: "",  null: false
    t.string   "full_name_th",           limit: 255, default: "",  null: false
    t.string   "citizen_id",             limit: 25,  default: "",  null: false, index: {name: "index_users_on_citizen_id", using: :btree}
    t.string   "employee_id",            limit: 25,  default: "",  null: false, index: {name: "index_users_on_employee_id", using: :btree}
    t.string   "sex",                    limit: 5,   default: "u", null: false
    t.integer  "role_id",                limit: 4,                 null: false, index: {name: "index_users_on_role_id", using: :btree}
    t.string   "state",                  limit: 3,                 null: false, index: {name: "index_users_on_state", using: :btree}
    t.date     "joined_date"
    t.date     "resign_date"
    t.date     "dob"
    t.string   "flag",                   limit: 1, index: {name: "index_users_on_flag", using: :btree}
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                  limit: 255, default: "",  null: false
    t.string   "text_password",          limit: 255, default: "",  null: false
    t.string   "encrypted_password",     limit: 255, default: "",  null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,   null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.integer  "failed_attempts",        limit: 4,   default: 0,   null: false
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.datetime "password_changed_at",    index: {name: "index_users_on_password_changed_at", using: :btree}
    t.string   "unique_session_id",      limit: 20
    t.datetime "last_activity_at"
    t.datetime "expired_at"
    t.string   "dsr_profile_id",         limit: 25
    t.string   "notes",                  limit: 120
    t.string   "domain_name",            limit: 150
    t.string   "auth_type",              limit: 10
    t.string   "atl_code",               limit: 15,  default: "", index: {name: "index_users_on_atl_code", using: :btree}
  end

  create_view "current_extension_agent_maps", <<-'END_VIEW_CURRENT_EXTENSION_AGENT_MAPS', :force => true
(select `u`.`extension` AS `extension`,`u`.`did` AS `did`,`u`.`agent_id` AS `agent_id`,1 AS `priority_no` from `user_extension_maps` `u` where (`u`.`agent_id` > 0)) union (select `e`.`number` AS `extension`,`d`.`number` AS `did`,`u`.`id` AS `agent_id`,99 AS `priority_no` from ((`extensions` `e` join `users` `u` on((`e`.`user_id` = `u`.`id`))) left join `dids` `d` on((`d`.`extension_id` = `e`.`id`)))) order by `extension`,`priority_no`
  END_VIEW_CURRENT_EXTENSION_AGENT_MAPS

  create_table "custom_dictionaries", force: :cascade do |t|
    t.string   "word",        limit: 150
    t.string   "spoken_word", limit: 150
    t.string   "class_map",   limit: 50
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string   "name",       limit: 200, null: false
    t.string   "psn_id",     limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "sex",        limit: 1
  end

  create_table "display_column_tables", force: :cascade do |t|
    t.string   "table_name",    limit: 50,               null: false, index: {name: "index_tbln", using: :btree}
    t.string   "column_name",   limit: 50,               null: false
    t.string   "variable_name", limit: 100,              null: false
    t.string   "sortable",      limit: 1,   default: "", null: false
    t.integer  "order_no",      limit: 4,   default: 0,  null: false
    t.string   "flag",          limit: 1,   default: "", null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "searchable",    limit: 1,   default: "", null: false
    t.string   "column_type",   limit: 50
  end

  create_table "display_logs", primary_key: "uniqueId", force: :cascade do |t|
    t.integer  "site_id",        limit: 4
    t.integer  "device_id",      limit: 4
    t.integer  "channel_id",     limit: 4
    t.integer  "system_id",      limit: 4
    t.integer  "call_reference", limit: 4
    t.string   "extension",      limit: 20
    t.string   "call_direction", limit: 10
    t.datetime "display_time"
    t.string   "number1",        limit: 50
    t.string   "number2",        limit: 50
    t.string   "transfer",       limit: 25
    t.string   "busy",           limit: 25
    t.string   "hasduration",    limit: 25
    t.string   "call_id",        limit: 50, index: {name: "index_call", using: :btree}
    t.string   "answer_time",    limit: 20
    t.string   "monitor",        limit: 25
    t.string   "flag_tranfer",   limit: 5
  end

  create_table "django_migrations", force: :cascade do |t|
    t.string   "app",     limit: 255,               null: false
    t.string   "name",    limit: 255,               null: false
    t.datetime "applied", precision: 6, null: false
  end

  create_table "statistic_calendars", force: :cascade do |t|
    t.date    "stats_date",      null: false, index: {name: "indext", using: :btree}
    t.integer "stats_year",      limit: 4, null: false
    t.integer "stats_yearmonth", limit: 4, null: false
    t.integer "stats_week",      limit: 4, null: false
    t.integer "stats_day",       limit: 4, null: false
    t.integer "stats_hour",      limit: 4, null: false
    t.integer "stats_yearweek",  limit: 4
  end
  add_index "statistic_calendars", ["stats_date", "stats_hour"], name: "index_datehr", unique: true, using: :btree

  create_view "dmy_calendars", <<-'END_VIEW_DMY_CALENDARS', :force => true
select max(`statistic_calendars`.`id`) AS `id`,`statistic_calendars`.`stats_date` AS `stats_date`,`statistic_calendars`.`stats_day` AS `stats_day`,`statistic_calendars`.`stats_year` AS `stats_year`,`statistic_calendars`.`stats_week` AS `stats_week`,(`statistic_calendars`.`stats_week` + (`statistic_calendars`.`stats_year` * 100)) AS `stats_yearweek`,`statistic_calendars`.`stats_yearmonth` AS `stats_yearmonth` from `statistic_calendars` where (`statistic_calendars`.`stats_hour` < 0) group by `statistic_calendars`.`stats_date`,`statistic_calendars`.`stats_day`,`statistic_calendars`.`stats_hour`,`statistic_calendars`.`stats_year`,`statistic_calendars`.`stats_yearmonth`
  END_VIEW_DMY_CALENDARS

  create_table "document_templates", force: :cascade do |t|
    t.string   "title",         limit: 150,                     null: false
    t.string   "description",   limit: 255
    t.binary   "file_data",     limit: 4294967295
    t.string   "flag",          limit: 255,        default: "", null: false
    t.string   "file_path",     limit: 100
    t.string   "file_type",     limit: 10
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "file_hash",     limit: 200
    t.integer  "file_size",     limit: 4,          default: 0,  null: false
    t.text     "mapped_fields", limit: 65535
  end

  create_table "dsrresult_logs", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8, index: {name: "index_dsrresult_logs_on_voice_log_id", using: :btree}
    t.integer  "agent_id",     limit: 4
    t.string   "server_name",  limit: 20
    t.datetime "start_time"
    t.text     "result",       limit: 65535
  end

  create_table "emotion_infos", force: :cascade do |t|
    t.string "title",      limit: 100, null: false
    t.string "image_name", limit: 100, null: false
  end

  create_table "evaluation_answers", force: :cascade do |t|
    t.integer  "evaluation_question_id", limit: 4
    t.string   "answer_type",            limit: 50
    t.text     "answer_list",            limit: 65535
    t.float    "max_score",              limit: 24
    t.string   "flag",                   limit: 1
    t.integer  "revision_no",            limit: 4
    t.string   "ana_settings",           limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "evaluation_assigned_tasks", force: :cascade do |t|
    t.integer  "user_id",            limit: 4,                null: false
    t.integer  "evaluation_task_id", limit: 4
    t.integer  "voice_log_id",       limit: 8
    t.integer  "assigned_by",        limit: 4
    t.datetime "assigned_at"
    t.datetime "expiry_at"
    t.datetime "updated_at"
    t.string   "flag",               limit: 255, default: "", null: false
    t.integer  "record_count",       limit: 4,   default: 0,  null: false
    t.integer  "total_duration",     limit: 4,   default: 0,  null: false
    t.integer  "unassigned_by",      limit: 4
  end

  create_table "evaluation_calls", force: :cascade do |t|
    t.integer "evaluation_plan_id", limit: 4,              null: false, index: {name: "index_evplan", using: :btree}
    t.integer "evaluation_log_id",  limit: 4,              null: false, index: {name: "index_evl", using: :btree}
    t.integer "voice_log_id",       limit: 8,              null: false, index: {name: "index_vl", using: :btree}
    t.date    "call_date",          index: {name: "index_cdate_log", with: ["evaluation_log_id"], using: :btree}
    t.time    "call_time"
    t.string  "ani",                limit: 25
    t.string  "dnis",               limit: 25
    t.integer "duration",           limit: 4,  default: 0
  end

  create_table "evaluation_comments", force: :cascade do |t|
    t.integer "evaluation_log_id", limit: 4,    null: false, index: {name: "index_evl", using: :btree}
    t.string  "comment_type",      limit: 1,    null: false
    t.string  "comment",           limit: 1500, null: false
  end

  create_table "evaluation_doc_attachments", force: :cascade do |t|
    t.integer  "evaluation_log_id",    limit: 4,                     null: false, index: {name: "index_evl", using: :btree}
    t.integer  "document_template_id", limit: 4,                     null: false
    t.text     "doc_data",             limit: 16777215
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "flag",                 limit: 1,        default: "", null: false
    t.integer  "created_by",           limit: 4
    t.integer  "updated_by",           limit: 4
  end

  create_table "evaluation_grade_settings", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "flag",       limit: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "evaluation_grades", force: :cascade do |t|
    t.string  "name",                        limit: 25,                null: false
    t.float   "upper_bound",                 limit: 24,  default: 0.0, null: false
    t.float   "lower_bound",                 limit: 24,  default: 0.0, null: false
    t.string  "flag",                        limit: 255
    t.integer "evaluation_grade_setting_id", limit: 4, index: {name: "fk_evaluation_grades_evaluation_grade_setting_id", using: :btree}
    t.float   "point",                       limit: 24
  end

  create_view "evaluation_grade_current", <<-'END_VIEW_EVALUATION_GRADE_CURRENT', :force => true
select `p`.`id` AS `evaluation_plan_id`,`g`.`name` AS `name`,`g`.`lower_bound` AS `lower_bound`,`g`.`upper_bound` AS `upper_bound` from ((`evaluation_plans` `p` join `evaluation_grades` `g` on((`p`.`evaluation_grade_setting_id` = `g`.`evaluation_grade_setting_id`))) join `evaluation_grade_settings` `s` on((`s`.`id` = `g`.`evaluation_grade_setting_id`))) where (`g`.`flag` <> 'D') order by `p`.`id`,`g`.`upper_bound` desc
  END_VIEW_EVALUATION_GRADE_CURRENT

  create_table "evaluation_logs", force: :cascade do |t|
    t.integer  "evaluation_plan_id", limit: 4,               null: false, index: {name: "index_eplan", using: :btree}
    t.integer  "user_id",            limit: 4,               null: false, index: {name: "index_usr", using: :btree}
    t.integer  "group_id",           limit: 4
    t.integer  "evaluated_by",       limit: 4,               null: false, index: {name: "index_edate_by", with: ["evaluated_at"], using: :btree}
    t.datetime "evaluated_at",       index: {name: "index_edate", using: :btree}
    t.integer  "updated_by",         limit: 4
    t.datetime "updated_at"
    t.integer  "checked_by",         limit: 4
    t.datetime "checked_at"
    t.string   "checked_result",     limit: 1
    t.string   "flag",               limit: 1,  default: "", null: false, index: {name: "index_flg_id", with: ["id"], using: :btree}
    t.integer  "revision_no",        limit: 4,  default: 0,  null: false
    t.integer  "ref_log_id",         limit: 4
    t.float    "score",              limit: 24
    t.float    "weighted_score",     limit: 24
    t.integer  "supervisor_id",      limit: 4
    t.integer  "chief_id",           limit: 4
  end
  add_index "evaluation_logs", ["evaluated_by", "evaluated_at"], name: "index_test", using: :btree

  create_table "evaluation_question_groups", force: :cascade do |t|
    t.string   "title",        limit: 150
    t.integer  "order_no",     limit: 4,   default: 0, null: false
    t.string   "flag",         limit: 1
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "report_title", limit: 255
  end

  create_table "evaluation_questions", force: :cascade do |t|
    t.string   "title",             limit: 150
    t.integer  "order_no",          limit: 4
    t.integer  "question_group_id", limit: 4
    t.string   "flag",              limit: 1
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "code_name",         limit: 50
    t.string   "report_title",      limit: 255
  end

  create_view "evaluation_question_display", <<-'END_VIEW_EVALUATION_QUESTION_DISPLAY', :force => true
select `g`.`id` AS `question_group_id`,`g`.`title` AS `question_group_title`,`g`.`order_no` AS `group_order_no`,`q`.`id` AS `question_id`,`q`.`title` AS `question_title`,`q`.`order_no` AS `order_no` from (`evaluation_question_groups` `g` join `evaluation_questions` `q` on((`g`.`id` = `q`.`question_group_id`))) order by `g`.`title`,`q`.`title`
  END_VIEW_EVALUATION_QUESTION_DISPLAY

  create_table "evaluation_question_stats", force: :cascade do |t|
    t.integer "evaluation_question_id", limit: 4,                null: false
    t.date    "call_date",              index: {name: "index_quest_date", with: ["evaluation_question_id"], using: :btree}
    t.string  "choice_title",           limit: 255, default: "", null: false
    t.integer "record_count",           limit: 4,   default: 0,  null: false
    t.integer "agent_id",               limit: 4
    t.integer "group_id",               limit: 4
    t.integer "evaluation_plan_id",     limit: 4, index: {name: "fk_evaluation_question_stats_evaluation_plan_id", using: :btree}, foreign_key: {references: "evaluation_plans", name: "fk_evaluation_question_stats_evaluation_plan_id", on_update: :restrict, on_delete: :restrict}
  end

  create_table "evaluation_score_logs", force: :cascade do |t|
    t.integer "evaluation_log_id",      limit: 4,     null: false, index: {name: "index_evl", using: :btree}
    t.float   "weighted_score",         limit: 24
    t.string  "comment",                limit: 180
    t.integer "evaluation_question_id", limit: 4
    t.integer "question_group_id",      limit: 4
    t.float   "max_score",              limit: 24
    t.float   "actual_score",           limit: 24
    t.text    "answer",                 limit: 65535
    t.integer "revision_no",            limit: 4
  end

  create_table "evaluation_scores", force: :cascade do |t|
    t.integer "evaluation_criteria_id", limit: 4,     null: false, index: {name: "index_ecrit", using: :btree}
    t.string  "answer_type",            limit: 50
    t.text    "answer_list",            limit: 65535
    t.float   "max_score",              limit: 24
  end

  create_table "evaluation_task_attrs", force: :cascade do |t|
    t.integer  "evaluation_task_id", limit: 4,   null: false, index: {name: "index_etask", using: :btree}
    t.string   "attr_type",          limit: 80,  null: false
    t.integer  "attr_id",            limit: 4
    t.string   "attr_val",           limit: 300
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "evaluation_tasks", force: :cascade do |t|
    t.string   "title",       limit: 100
    t.string   "description", limit: 300
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "flag",        limit: 3,   default: "", null: false
  end

  create_table "export_conditions", force: :cascade do |t|
    t.integer  "export_task_id",   limit: 4,        null: false, index: {name: "index_export_conditions_on_export_task_id", using: :btree}
    t.text     "condition_string", limit: 16777215
    t.datetime "created_at"
  end

  create_table "export_logs", force: :cascade do |t|
    t.integer  "export_task_id",   limit: 4,                    null: false, index: {name: "index_task", using: :btree}
    t.text     "condition_string", limit: 16777215
    t.date     "target_call_date"
    t.string   "status",           limit: 3
    t.string   "flag",             limit: 3
    t.text     "result_string",    limit: 65535
    t.string   "digest_string",    limit: 45
    t.integer  "retry_count",      limit: 4,        default: 0, null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "export_tasks", force: :cascade do |t|
    t.string   "name",             limit: 50,               null: false
    t.string   "desc",             limit: 255
    t.string   "schedule_type",    limit: 30,               null: false, index: {name: "index_export_tasks_on_schedule_type", using: :btree}
    t.string   "category",         limit: 50, index: {name: "index_export_tasks_on_category", using: :btree}
    t.string   "filename",         limit: 250
    t.string   "audio_type",       limit: 10
    t.string   "compression_type", limit: 10
    t.datetime "start_at"
    t.string   "flag",             limit: 3,   default: ""
    t.datetime "processed_at"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "faq_answers", force: :cascade do |t|
    t.integer  "faq_question_id",    limit: 4,                    null: false
    t.text     "content",            limit: 65535
    t.text     "conditions",         limit: 65535
    t.integer  "revision",           limit: 4,     default: 0,    null: false
    t.string   "flag",               limit: 5,     default: "",   null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.boolean  "conditional_enable", default: true, null: false
  end

  create_table "faq_question_patterns", force: :cascade do |t|
    t.integer  "faq_question_id", limit: 4,                     null: false
    t.text     "pattern",         limit: 16777215
    t.integer  "revision",        limit: 4,        default: 0,  null: false
    t.string   "flag",            limit: 255,      default: "", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "faq_questions", force: :cascade do |t|
    t.string   "question",                    limit: 255,                null: false
    t.datetime "created_at",                  null: false
    t.string   "flag",                        limit: 3,   default: "",   null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "enable",                      default: true
    t.integer  "faq_question_patterns_value", limit: 4
  end

  create_table "faq_tags", force: :cascade do |t|
    t.integer  "faq_question_id", limit: 4,                null: false, index: {name: "index_faq_tags_on_faq_question_id", using: :btree}
    t.string   "tag_name",        limit: 255, index: {name: "index_faq_tags_on_tag_name", using: :btree}
    t.string   "tag_type",        limit: 255
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "flag",            limit: 255, default: "", null: false
  end
  add_index "faq_tags", ["tag_name"], name: "tag_name", type: :fulltext
  add_index "faq_tags", ["tag_name"], name: "tag_name_2", type: :fulltext
  add_index "faq_tags", ["tag_name"], name: "tag_name_3", type: :fulltext
  add_index "faq_tags", ["tag_name"], name: "tag_name_4", type: :fulltext
  add_index "faq_tags", ["tag_name"], name: "tag_name_5", type: :fulltext
  add_index "faq_tags", ["tag_name"], name: "tag_name_6", type: :fulltext

  create_table "group_member_histories", force: :cascade do |t|
    t.integer  "group_id",     limit: 4
    t.integer  "user_id",      limit: 4
    t.string   "member_type",  limit: 2,   null: false, index: {name: "index_mem1", with: ["user_id", "created_date", "deleted_date"], using: :btree}
    t.string   "display_name", limit: 100
    t.datetime "created_date", null: false
    t.datetime "deleted_date", null: false
  end
  add_index "group_member_histories", ["member_type", "user_id"], name: "index_mem2", using: :btree

  create_table "group_member_types", force: :cascade do |t|
    t.string  "member_type", limit: 255,             null: false, index: {name: "index_memtype", using: :btree}
    t.string  "title",       limit: 255,             null: false
    t.integer "order_no",    limit: 4,   default: 0, null: false
  end

  create_table "group_members", force: :cascade do |t|
    t.integer  "group_id",    limit: 4
    t.integer  "user_id",     limit: 4
    t.string   "member_type", limit: 2, null: false, index: {name: "index_group_members_on_member_type_and_group_id_and_user_id", with: ["group_id", "user_id"], unique: true, using: :btree}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "group_members", ["member_type", "group_id"], name: "index_group_members_on_member_type_and_group_id", using: :btree
  add_index "group_members", ["member_type", "user_id"], name: "index_group_members_on_member_type_and_user_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.string   "name",        limit: 100,              null: false, index: {name: "index_groups_on_name", using: :btree}
    t.string   "short_name",  limit: 100,              null: false, index: {name: "index_groups_on_short_name", using: :btree}
    t.string   "description", limit: 100
    t.integer  "level_no",    limit: 4,   default: 0,  null: false
    t.integer  "parent_id",   limit: 4,   default: 0,  null: false, index: {name: "index_groups_on_parent_id", using: :btree}
    t.string   "seq_no",      limit: 45,  default: "", null: false, index: {name: "index_groups_on_seq_no", using: :btree}
    t.string   "pathname",    limit: 255, default: "", null: false
    t.string   "flag",        limit: 1,   default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ldap_dn",     limit: 150
    t.string   "group_type",  limit: 25
  end

  create_table "hangup_calls", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8,  null: false, index: {name: "index_hangup_calls_on_voice_log_id", using: :btree}
    t.string   "call_id",      limit: 30, null: false, index: {name: "index_hangup_calls_on_call_id", using: :btree}
    t.datetime "start_time",   null: false
    t.datetime "created_at"
  end

  create_table "keyword_statistics", force: :cascade do |t|
    t.integer  "stats_date_id", limit: 4,             null: false
    t.integer  "stats_id",      limit: 4,             null: false
    t.integer  "stats_type",    limit: 4,             null: false, index: {name: "index_d_report", with: ["stats_id", "stats_date_id", "keyword_id"], unique: true, using: :btree}
    t.integer  "keyword_id",    limit: 4,             null: false
    t.integer  "total",         limit: 4, default: 0
    t.datetime "updated_at"
  end

  create_table "keyword_types", force: :cascade do |t|
    t.string   "name",           limit: 50
    t.string   "description",    limit: 150
    t.string   "flag",           limit: 1,     default: "", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "notify_flag",    limit: 3
    t.text     "notify_details", limit: 65535
  end

  create_table "keywords", force: :cascade do |t|
    t.string   "name",               limit: 100,                null: false
    t.integer  "keyword_type_id",    limit: 4,                  null: false, index: {name: "index_keywords_on_keyword_type_id", using: :btree}
    t.string   "flag",               limit: 1,     default: "", null: false
    t.integer  "parent_id",          limit: 4,     default: 0,  null: false, index: {name: "index_keywords_on_parent_id", using: :btree}
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "bg_color",           limit: 10
    t.string   "fg_color",           limit: 10
    t.string   "channel_type",       limit: 1
    t.string   "notify_flag",        limit: 3
    t.text     "notify_details",     limit: 65535
    t.text     "detection_settings", limit: 65535
    t.string   "subtype",            limit: 3
  end

  create_view "latest_computer_logs", <<-'END_VIEW_LATEST_COMPUTER_LOGS', :force => true
select `computer_logs`.`remote_ip` AS `remote_ip`,max(`computer_logs`.`check_time`) AS `max_check_time` from `computer_logs` group by `computer_logs`.`remote_ip`
  END_VIEW_LATEST_COMPUTER_LOGS

  create_table "location_infos", force: :cascade do |t|
    t.string   "name",       limit: 50,              null: false
    t.string   "code_name",  limit: 20
    t.string   "flag",       limit: 1,  default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "logger_channels", id: false, force: :cascade do |t|
    t.integer "site_id",      limit: 4,               null: false, index: {name: "index_ssdc", with: ["system_id", "device_id", "channel_id"], using: :btree}
    t.integer "system_id",    limit: 4,               null: false
    t.integer "device_id",    limit: 4,               null: false
    t.integer "channel_id",   limit: 4,               null: false
    t.integer "user_id",      limit: 4,  default: 0,  null: false
    t.string  "extension",    limit: 10, default: "", null: false
    t.string  "phone_number", limit: 50
    t.string  "call_id",      limit: 50
    t.string  "status",       limit: 25
  end

  create_table "message_logs", force: :cascade do |t|
    t.string   "message_type",       limit: 50, index: {name: "index_message_logs_on_message_type", using: :btree}
    t.integer  "who_sent",           limit: 4
    t.integer  "who_receive",        limit: 4
    t.integer  "reference_id",       limit: 4
    t.string   "read_flag",          limit: 1
    t.string   "useful_flag",        limit: 1
    t.string   "message_uuid",       limit: 50
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "voice_log_id",       limit: 8, index: {name: "index_voice_id", using: :btree}
    t.integer  "item_id",            limit: 4
    t.string   "comment",            limit: 255
    t.datetime "display_cli_at"
    t.datetime "display_at"
    t.integer  "start_msec",         limit: 4
    t.integer  "end_msec",           limit: 4
    t.datetime "dsr_ut_ended_at"
    t.datetime "dsr_rs_created_at"
    t.datetime "dsr_rs_accepted_at"
  end
  add_index "message_logs", ["message_type", "reference_id"], name: "index_type_id", using: :btree

  create_table "message_logs_2", force: :cascade do |t|
    t.string   "message_type",       limit: 50, index: {name: "index_message_logs_on_message_type", using: :btree}
    t.integer  "who_sent",           limit: 4
    t.integer  "who_receive",        limit: 4
    t.integer  "reference_id",       limit: 4
    t.string   "read_flag",          limit: 1
    t.string   "useful_flag",        limit: 1
    t.string   "message_uuid",       limit: 50
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "voice_log_id",       limit: 8, index: {name: "index_voice_id", using: :btree}
    t.integer  "item_id",            limit: 4
    t.string   "comment",            limit: 255
    t.datetime "display_cli_at"
    t.datetime "display_at"
    t.integer  "start_msec",         limit: 4
    t.integer  "end_msec",           limit: 4
    t.datetime "dsr_ut_ended_at"
    t.datetime "dsr_rs_created_at"
    t.datetime "dsr_rs_accepted_at"
  end
  add_index "message_logs_2", ["message_type", "reference_id"], name: "index_type_id", using: :btree

  create_table "message_logs_copy", force: :cascade do |t|
    t.string   "message_type",       limit: 50, index: {name: "index_message_logs_on_message_type", using: :btree}
    t.integer  "who_sent",           limit: 4
    t.integer  "who_receive",        limit: 4
    t.integer  "reference_id",       limit: 4
    t.string   "read_flag",          limit: 1
    t.string   "useful_flag",        limit: 1
    t.string   "message_uuid",       limit: 50
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "voice_log_id",       limit: 8, index: {name: "index_voice_id", using: :btree}
    t.integer  "item_id",            limit: 4
    t.string   "comment",            limit: 255
    t.datetime "display_cli_at"
    t.datetime "display_at"
    t.integer  "start_msec",         limit: 4
    t.integer  "end_msec",           limit: 4
    t.datetime "dsr_ut_ended_at"
    t.datetime "dsr_rs_created_at"
    t.datetime "dsr_rs_accepted_at"
  end
  add_index "message_logs_copy", ["message_type", "reference_id"], name: "index_type_id", using: :btree

  create_table "operation_logs", force: :cascade do |t|
    t.datetime "created_at"
    t.string   "log_type",    limit: 255
    t.string   "module_name", limit: 255
    t.string   "event_type",  limit: 255
    t.string   "created_by",  limit: 255
    t.string   "remote_ip",   limit: 255
    t.string   "message",     limit: 255
    t.text     "log_detail",  limit: 65535
    t.integer  "target_id",   limit: 4
    t.string   "target_name", limit: 255
  end

  create_table "permissions", force: :cascade do |t|
    t.integer  "role_id",      limit: 4, null: false, index: {name: "index_permissions_on_role_id_and_privilege_id", with: ["privilege_id"], unique: true, using: :btree}
    t.integer  "privilege_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phoneno_statistics", force: :cascade do |t|
    t.integer  "stats_date_id",    limit: 4,                null: false, index: {name: "index_date1", using: :btree}
    t.string   "number",           limit: 25, index: {name: "index2", using: :btree}
    t.string   "formatted_number", limit: 25
    t.string   "phone_type",       limit: 3,   default: "", null: false, index: {name: "index_number_type", using: :btree}
    t.string   "stats_type",       limit: 255,              null: false
    t.integer  "total",            limit: 4,   default: 0
    t.datetime "updated_at"
  end
  add_index "phoneno_statistics", ["number"], name: "index_number", using: :btree

  create_table "privileges", force: :cascade do |t|
    t.string "category",     limit: 100, default: "", null: false
    t.string "module_name",  limit: 100,              null: false, index: {name: "index_privileges_on_module_name_and_event_name", with: ["event_name"], using: :btree}
    t.string "event_name",   limit: 100,              null: false
    t.string "section",      limit: 255,              null: false
    t.string "description",  limit: 150, default: "", null: false
    t.string "display_name", limit: 100
    t.string "order_no",     limit: 20,  default: "", null: false
    t.string "flag",         limit: 2,   default: "", null: false
    t.string "link_name",    limit: 255
  end

  create_table "program_infos", force: :cascade do |t|
    t.string "name",      limit: 100
    t.string "bg_color",  limit: 10
    t.string "fg_color",  limit: 10
    t.string "proc_name", limit: 100
  end

  create_table "result_keywords", force: :cascade do |t|
    t.integer  "start_msec",   limit: 4,  default: 0
    t.integer  "end_msec",     limit: 4,  default: 0
    t.integer  "keyword_id",   limit: 4,               null: false
    t.integer  "voice_log_id", limit: 8,               null: false, index: {name: "index_result_keywords_on_voice_log_id", using: :btree}
    t.string   "flag",         limit: 1,  default: "", null: false
    t.datetime "updated_at",   null: false
    t.string   "result",       limit: 50
    t.integer  "channel",      limit: 4
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",         limit: 255,              null: false, index: {name: "index_roles_on_name", unique: true, using: :btree}
    t.integer  "priority_no",  limit: 4,   default: 0,  null: false
    t.string   "flag",         limit: 1,   default: "", null: false, index: {name: "index_roles_on_flag", using: :btree}
    t.string   "level",        limit: 5,   default: "", null: false, index: {name: "index_roles_on_level_and_name", with: ["name"], using: :btree}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ldap_dn",      limit: 150
    t.string   "landing_page", limit: 100
  end

  create_table "schedule_infos", force: :cascade do |t|
    t.string   "name",                limit: 100
    t.datetime "last_processed_time"
    t.string   "message",             limit: 255
    t.string   "status",              limit: 10
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "speech_recognition_tasks", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8,  default: 0, null: false, index: {name: "index_speech_recognition_tasks_on_voice_log_id", using: :btree}
    t.string   "call_id",      limit: 50
    t.datetime "start_time"
    t.integer  "channel_no",   limit: 4
    t.datetime "created_at"
  end

  create_table "speech_task_logs", force: :cascade do |t|
    t.string   "call_id",                    limit: 30
    t.integer  "voice_log_id",               limit: 8
    t.string   "voice_file_url",             limit: 200
    t.datetime "task_created_at"
    t.string   "recognize_mode",             limit: 15
    t.integer  "channel",                    limit: 4
    t.string   "speaker_type",               limit: 3
    t.string   "speechserver_version",       limit: 15
    t.datetime "start_task_at"
    t.datetime "start_recognize_at"
    t.string   "dsr_session_id",             limit: 10
    t.string   "dsr_mode",                   limit: 10
    t.string   "dsr_profile_id",             limit: 10
    t.float    "dsr_speed_vs_accuracy",      limit: 24
    t.string   "dsr_grammar_file_names",     limit: 50
    t.string   "dsr_server_name",            limit: 50
    t.integer  "dsr_volume",                 limit: 4
    t.integer  "dsr_snr",                    limit: 4
    t.float    "task_delay_time",            limit: 24
    t.float    "recognize_preprocess_time",  limit: 24
    t.float    "recognize_process_time",     limit: 24
    t.float    "recognize_postprocess_time", limit: 24
    t.float    "audio_load_time",            limit: 24
    t.float    "duration_of_audio",          limit: 24
    t.float    "rt",                         limit: 24
    t.integer  "sent_byte",                  limit: 4
    t.integer  "number_of_utterances",       limit: 4
    t.float    "duration_of_speaking_tx",    limit: 24
    t.float    "duration_of_speaking_rx",    limit: 24
    t.float    "duration_of_overwrap",       limit: 24
    t.float    "duration_of_silence",        limit: 24
    t.integer  "error",                      limit: 4
    t.datetime "last_error_at"
    t.string   "last_error_message",         limit: 200
  end

  create_table "system_consts", force: :cascade do |t|
    t.string "cate",       limit: 15,              null: false, index: {name: "index_system_consts_on_cate", using: :btree}
    t.string "code",       limit: 15,              null: false
    t.string "name",       limit: 50,              null: false
    t.string "flag",       limit: 1,  default: "", null: false
    t.string "as_default", limit: 1,  default: "", null: false
  end
  add_index "system_consts", ["cate", "code"], name: "index_system_consts_on_cate_and_code", unique: true, using: :btree

  create_table "table_infos", id: false, force: :cascade do |t|
    t.string   "db_name",      limit: 100, index: {name: "index_dbtbl", with: ["tbl_name"], unique: true, using: :btree}
    t.string   "tbl_name",     limit: 100
    t.string   "engine_name",  limit: 50
    t.integer  "rows_count",   limit: 4
    t.integer  "data_length",  limit: 4
    t.integer  "index_length", limit: 4
    t.integer  "data_free",    limit: 4
    t.datetime "updated_at"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",     limit: 4, index: {name: "index_taggings_on_tag_id_and_tagged_id", with: ["tagged_id"], unique: true, using: :btree}
    t.integer  "tagged_id",  limit: 8
    t.integer  "updated_by", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", force: :cascade do |t|
    t.string   "name",       limit: 100,             null: false
    t.integer  "parent_id",  limit: 4,   default: 0, null: false
    t.string   "color_code", limit: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tag_code",   limit: 20, index: {name: "index_tags_on_tag_code", using: :btree}
  end

  create_view "tags_maps", <<-'END_VIEW_TAGS_MAPS', :force => true
select `t1`.`id` AS `id`,`t1`.`name` AS `name`,if(isnull(`t2`.`id`),`t1`.`id`,`t2`.`id`) AS `tag_category_id`,if(isnull(`t2`.`id`),`t1`.`name`,`t2`.`name`) AS `tag_category_name`,if(isnull(`t2`.`id`),'C','') AS `is_tag_category` from (`tags` `t1` left join `tags` `t2` on((`t1`.`parent_id` = `t2`.`id`)))
  END_VIEW_TAGS_MAPS

  create_table "telephone_infos", force: :cascade do |t|
    t.string "number",      limit: 50, index: {name: "index_number", using: :btree}
    t.string "number_type", limit: 50
  end

  create_table "user_activity_logs", force: :cascade do |t|
    t.datetime "start_time",     index: {name: "index_stime", using: :btree}
    t.integer  "duration",       limit: 4
    t.string   "proc_name",      limit: 100
    t.string   "window_title",   limit: 255
    t.string   "login",          limit: 50
    t.integer  "user_id",        limit: 4,   default: 0, null: false, index: {name: "index_usr_tm", with: ["start_time"], using: :btree}
    t.string   "remote_ip",      limit: 30
    t.string   "mac_addr",       limit: 30
    t.string   "proc_exec_name", limit: 100
  end

  create_table "user_atl_attrs", force: :cascade do |t|
    t.integer  "user_id",              limit: 4,               null: false, index: {name: "index_user_atl_attrs_on_user_id", using: :btree}
    t.string   "operator_id",          limit: 15, default: "", null: false, index: {name: "index_user_atl_attrs_on_operator_id", using: :btree}
    t.string   "team_id",              limit: 15, default: "", null: false
    t.string   "performance_group_id", limit: 15, default: "", null: false
    t.string   "delinquent_no",        limit: 10, default: "", null: false
    t.string   "extension",            limit: 20, default: "", null: false
    t.string   "flag",                 limit: 3,  default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "grade",                limit: 5
    t.string   "section_id",           limit: 15
    t.string   "dummy_flag",           limit: 1
  end

  create_table "user_attributes", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,   null: false, index: {name: "index_user_attributes_on_user_id_and_attr_type", with: ["attr_type"], using: :btree}
    t.integer  "attr_type",  limit: 4,   null: false
    t.string   "attr_val",   limit: 255
    t.datetime "updated_at"
  end

  create_table "user_educations", force: :cascade do |t|
    t.integer  "user_id",     limit: 4,   null: false, index: {name: "index_user_educations_on_user_id", using: :btree}
    t.integer  "degree",      limit: 4
    t.string   "institution", limit: 120
    t.string   "subject",     limit: 120
    t.integer  "year_passed", limit: 4
    t.datetime "updated_at"
  end

  create_table "user_experiences", force: :cascade do |t|
    t.integer  "user_id",      limit: 4,               null: false, index: {name: "index_user_experiences_on_user_id", using: :btree}
    t.string   "position",     limit: 70
    t.string   "company_name", limit: 100
    t.integer  "length_work",  limit: 4,   default: 0, null: false
    t.string   "description",  limit: 200
    t.datetime "updated_at"
  end

  create_table "user_extension_logs", force: :cascade do |t|
    t.datetime "log_date",  null: false, index: {name: "index_user_extension_logs_on_log_date", using: :btree}
    t.string   "extension", limit: 15
    t.string   "did",       limit: 20
    t.integer  "agent_id",  limit: 4, index: {name: "index_user_extension_logs_on_agent_id", using: :btree}
  end

  create_table "user_pictures", force: :cascade do |t|
    t.integer "user_id",      limit: 4,                     null: false, index: {name: "index_user_pictures_on_user_id", using: :btree}
    t.binary  "pic_data",     limit: 16777215,              null: false
    t.string  "content_type", limit: 25
    t.integer "file_size",    limit: 4,        default: 0
    t.string  "flag",         limit: 1,        default: ""
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255,   null: false, index: {name: "index_versions_on_item_type_and_item_id", with: ["item_id"], using: :btree}
    t.integer  "item_id",    limit: 4,     null: false
    t.string   "event",      limit: 255,   null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object",     limit: 65535
    t.datetime "created_at"
  end

  create_table "voice_log_atlusr_maps", id: false, force: :cascade do |t|
    t.integer "voice_log_id", limit: 8, default: 0, null: false, index: {name: "index_vlatl", with: ["user_atl_id"], using: :btree}
    t.integer "user_atl_id",  limit: 4, default: 0, null: false
  end

  create_table "voice_log_attributes", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8,   null: false, index: {name: "index_id_attr_type", with: ["attr_type"], using: :btree}
    t.integer  "attr_type",    limit: 4,   null: false
    t.string   "attr_val",     limit: 255
    t.integer  "updated_by",   limit: 4
    t.datetime "updated_at"
    t.integer  "grouping_id",  limit: 8
  end

  create_table "voice_log_counters", force: :cascade do |t|
    t.integer  "voice_log_id", limit: 8,             null: false, index: {name: "index_vl", using: :btree}
    t.integer  "counter_type", limit: 4,             null: false
    t.integer  "valu",         limit: 4, default: 0
    t.datetime "updated_at"
  end

  create_table "voice_logs", force: :cascade do |t|
    t.integer  "site_id",        limit: 3
    t.integer  "system_id",      limit: 3
    t.integer  "device_id",      limit: 4
    t.integer  "channel_id",     limit: 4
    t.string   "ani",            limit: 50,  default: ""
    t.string   "dnis",           limit: 50,  default: ""
    t.string   "extension",      limit: 15,  default: ""
    t.integer  "duration",       limit: 4
    t.integer  "hangup_cause",   limit: 4
    t.integer  "call_reference", limit: 4
    t.integer  "agent_id",       limit: 4
    t.string   "voice_file_url", limit: 200, default: ""
    t.string   "call_direction", limit: 1,   default: ""
    t.datetime "start_time",     index: {name: "index_stime", using: :btree}
    t.string   "call_id",        limit: 45, index: {name: "index_call_id", using: :btree}
    t.string   "ori_call_id",    limit: 50, index: {name: "index_oricall_id", using: :btree}
    t.datetime "answer_time"
    t.string   "flag",           limit: 3,   default: ""
    t.date     "call_date",      index: {name: "index_date_agent", with: ["agent_id"], using: :btree}
  end

  create_table "voice_logs_details", force: :cascade do |t|
    t.integer  "site_id",             limit: 3
    t.integer  "system_id",           limit: 3
    t.integer  "device_id",           limit: 4
    t.integer  "channel_id",          limit: 4
    t.string   "ani",                 limit: 40,  default: ""
    t.string   "dnis",                limit: 40,  default: ""
    t.string   "extension",           limit: 15,  default: ""
    t.integer  "duration",            limit: 4
    t.integer  "hangup_cause",        limit: 4
    t.integer  "call_reference",      limit: 4
    t.integer  "agent_id",            limit: 4
    t.string   "voice_file_url",      limit: 200, default: ""
    t.string   "call_direction",      limit: 1,   default: ""
    t.datetime "start_time",          index: {name: "index_stime", using: :btree}
    t.string   "digest",              limit: 255
    t.string   "call_id",             limit: 45, index: {name: "index_call_id", using: :btree}
    t.string   "ori_call_id",         limit: 50, index: {name: "index_oricall_id", using: :btree}
    t.string   "flag_transfer",       limit: 4
    t.string   "xfer_ani",            limit: 45
    t.string   "xfer_dnis",           limit: 45
    t.string   "log_trans_ani",       limit: 80
    t.string   "log_trans_dnis",      limit: 80
    t.string   "log_trans_extension", limit: 80
    t.string   "ext_tranfer",         limit: 25
    t.datetime "answer_time"
    t.string   "flag",                limit: 3,   default: ""
  end

  create_table "voice_logs_today", force: :cascade do |t|
    t.integer  "site_id",             limit: 3
    t.integer  "system_id",           limit: 3
    t.integer  "device_id",           limit: 4
    t.integer  "channel_id",          limit: 4
    t.string   "ani",                 limit: 40,  default: ""
    t.string   "dnis",                limit: 40,  default: ""
    t.string   "extension",           limit: 15,  default: ""
    t.integer  "duration",            limit: 4
    t.integer  "hangup_cause",        limit: 4
    t.integer  "call_reference",      limit: 4
    t.integer  "agent_id",            limit: 4
    t.string   "voice_file_url",      limit: 200, default: ""
    t.string   "call_direction",      limit: 1,   default: ""
    t.datetime "start_time",          index: {name: "index_stime", using: :btree}
    t.string   "digest",              limit: 255
    t.string   "call_id",             limit: 45, index: {name: "index_call_id", using: :btree}
    t.string   "ori_call_id",         limit: 50, index: {name: "index_oricall_id", using: :btree}
    t.string   "flag_transfer",       limit: 4
    t.string   "xfer_ani",            limit: 45
    t.string   "xfer_dnis",           limit: 45
    t.string   "log_trans_ani",       limit: 80
    t.string   "log_trans_dnis",      limit: 80
    t.string   "log_trans_extension", limit: 80
    t.string   "ext_tranfer",         limit: 25
    t.datetime "answer_time"
    t.string   "flag",                limit: 3,   default: ""
  end

  create_table "wf_task_states", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "wf_task_transitions", force: :cascade do |t|
    t.integer  "wf_task_id",       limit: 4
    t.integer  "wf_task_state_id", limit: 4
    t.integer  "assignee_id",      limit: 4
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "prev_state_id",    limit: 4
    t.string   "flag",             limit: 3
  end

  create_table "wf_tasks", force: :cascade do |t|
    t.integer  "voice_log_id",      limit: 8
    t.integer  "evaluation_log_id", limit: 4
    t.integer  "last_state_id",     limit: 4
    t.datetime "content_time"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "assignee_id",       limit: 4
    t.string   "flag",              limit: 3
  end

  create_table "word_clouds", force: :cascade do |t|
    t.date    "call_date"
    t.string  "text",        limit: 100
    t.string  "type_tags",   limit: 100
    t.integer "total_count", limit: 4
  end

  create_table "xfer_logs", force: :cascade do |t|
    t.integer  "xfer_id",         limit: 8
    t.datetime "xfer_start_time", index: {name: "index_xfer1", using: :btree}
    t.string   "xfer_ani",        limit: 50
    t.string   "xfer_dnis",       limit: 50
    t.string   "xfer_extension",  limit: 50, index: {name: "index_xfer2", with: ["xfer_ani", "xfer_id"], using: :btree}
    t.string   "xfer_call_id1",   limit: 50
    t.string   "xfer_call_id2",   limit: 50
    t.datetime "updated_on"
    t.string   "msg_type",        limit: 10
    t.string   "ip",              limit: 50
    t.string   "xfer_type",       limit: 20
    t.string   "mapping_status",  limit: 20
    t.string   "sender",          limit: 10
    t.string   "ext_tranfer",     limit: 25
    t.string   "flag_tranfer",    limit: 5
  end

end
