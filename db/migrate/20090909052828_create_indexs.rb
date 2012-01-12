class CreateIndexs < ActiveRecord::Migration
  def self.up

    add_index :voice_logs, [:start_date,:start_time,:agent_id], :name => 'vc_index1'
    add_index :voice_logs, :customer_id
    #add_index :voice_logs, :ani
    #add_index :voice_logs, :dnis
    add_index :call_bookmarks, :voice_log_id
    add_index :call_informations, :voice_log_id
    add_index :result_keywords, :voice_log_id
    add_index :result_keywords, :keyword_id
    add_index :result_keywords, [:voice_log_id,:keyword_id], :name => 'rs_index1'
    add_index :customers, :customer_name
	
  end

  def self.down

    remove_index :voice_logs, [:start_date,:start_time,:agent_id], :name => 'vc_index1'
    remove_index :voice_logs, :customer_id
    #remove_index :voice_logs, :ani
    #remove_index :voice_logs, :dnis    
    remove_index :call_bookmarks, :voice_log_id
    remove_index :call_informations, :voice_log_id
    remove_index :result_keywords, :voice_log_id
    remove_index :result_keywords, :keyword_id
    remove_index :result_keywords, [:voice_log_id,:keyword_id], :name => 'rs_index1'
    remove_index :customers, :customer_name
	
  end
end
