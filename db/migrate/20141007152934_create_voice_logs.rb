class CreateVoiceLogs < ActiveRecord::Migration
  def change
    create_table :voice_logs do |t|
      t.integer       :site_id,         limit: 3, foreign_key: false 
      t.integer       :system_id,       limit: 3, foreign_key: false 
      t.integer       :device_id,       foreign_key: false 
      t.integer       :channel_id,      foreign_key: false 
      t.string        :ani,             default: "", limit: 50
      t.string        :dnis,            default: "", limit: 50
      t.string        :extension,       default: "", limit: 10
      t.integer       :duration
      t.integer       :hangup_cause
      t.integer       :call_reference
      t.integer       :agent_id,        foreign_key: false 
      t.string        :voice_file_url,  default: "", limit: 200
      t.string        :call_direction,  default: "", limit: 1
      t.datetime      :start_time
      t.string        :call_id,         limit: 45, foreign_key: false 
      t.string        :ori_call_id,     limit: 50, foreign_key: false 
      t.datetime      :answer_time
      t.string        :flag,            limit: 3, default: ""
    end
    change_column :voice_logs, :id, :integer, limit: 8, primary_key: true
  end
end