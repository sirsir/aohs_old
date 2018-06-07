class CreateVoiceLogsDetails < ActiveRecord::Migration
  def change
    create_table :voice_logs_details do |t|
      t.integer       :site_id,         limit: 3, foreign_key: false 
      t.integer       :system_id,       limit: 3, foreign_key: false 
      t.integer       :device_id,       foreign_key: false 
      t.integer       :channel_id,      foreign_key: false
      t.string        :ani,             default: "", limit: 40
      t.string        :dnis,            default: "", limit: 40
      t.string        :extension,       default: "", limit: 10
      t.integer       :duration
      t.integer       :hangup_cause
      t.integer       :call_reference
      t.integer       :agent_id,        foreign_key: false 
      t.string        :voice_file_url,  default: "", limit: 200
      t.string        :call_direction,  default: "", limit: 1
      t.datetime      :start_time
      t.string        :digest
      t.string        :call_id,         limit: 45, foreign_key: false 
      t.string        :ori_call_id,     limit: 50, foreign_key: false
      t.string        :flag_transfer,   limit: 4
      t.string        :xfer_ani,        limit: 45
      t.string        :xfer_dnis,       limit: 45
      t.string        :log_trans_ani,   limit: 80
      t.string        :log_trans_dnis,  limit: 80
      t.string        :log_trans_extension, limit: 80
      t.string        :ext_tranfer,     limit: 25
      t.datetime      :answer_time
      t.string        :flag,            limit: 3, default: ""
    end
    change_column :voice_logs_details, :id, :integer, limit: 8, primary_key: true
    execute "CREATE TABLE voice_logs_today LIKE voice_logs_details;"
    # fixed auto increment
    execute "ALTER TABLE voice_logs_today MODIFY COLUMN id BIGINT auto_increment"
    execute "ALTER TABLE voice_logs_details MODIFY COLUMN id BIGINT auto_increment"
  end
end