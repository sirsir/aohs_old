class CreateUserActivityLogs < ActiveRecord::Migration
  def change
    create_table :user_activity_logs do |t|
      t.datetime    :start_time
      t.integer     :duration
      t.string      :proc_name,       limit: 100
      t.string      :window_title,    limit: 255
      t.string      :login,           limit: 50
      t.integer     :user_id,         null: false, default: 0, foreign_key: false
      t.string      :remote_ip,       limit: 30
      t.string      :mac_addr,        limit: 30
    end
    add_index :user_activity_logs, :start_time, name: 'index_stime'
    add_index :user_activity_logs, [:user_id, :start_time], name: 'index_usr_tm'
  end
end
