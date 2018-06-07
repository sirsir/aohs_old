class CreateCallTrackingLogs < ActiveRecord::Migration
  def change
    create_table :call_tracking_logs do |t|
      t.integer       :tracking_type,     null: false
      t.integer       :user_id,           null: false, foreign_key: false
      t.integer       :voice_log_id,      null: false, foreign_key: false, limit: 8
      t.integer       :listened_sec
      t.string        :request_id,        limit: 100, foreign_key: false
      t.string        :session_id,        limit: 100, foreign_key: false
      t.string        :remote_ip,         limit: 20
      t.datetime      :created_at
    end
    add_index :call_tracking_logs, :voice_log_id, name: 'index_vl'
    add_index :call_tracking_logs, :created_at, name: 'index_crtd'
  end
end
