class AddVoiceLogsIndex < ActiveRecord::Migration
  def change
    add_index :voice_logs, :ori_call_id, name: 'index_oricall_id'    
    add_index :voice_logs_today, :ori_call_id, name: 'index_oricall_id'
    add_index :voice_logs_details, :ori_call_id, name: 'index_oricall_id'
  end
end
