class AddIndexVoiceLogs < ActiveRecord::Migration
  def change
    add_index :voice_logs,  :call_id, name: 'index_call_id'
    add_index :voice_logs,  :start_time, name: 'index_stime'
    
    add_index :voice_logs_today,  :call_id, name: 'index_call_id'
    add_index :voice_logs_today,  :start_time, name: 'index_stime'
    
    add_index :voice_logs_details,  :call_id, name: 'index_call_id'
    add_index :voice_logs_details,  :start_time, name: 'index_stime'
  end
end
