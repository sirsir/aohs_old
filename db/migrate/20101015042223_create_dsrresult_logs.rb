class CreateDsrresultLogs < ActiveRecord::Migration
  def self.up
    create_table :dsrresult_logs do |t|
	t.column	:voice_log_id,	:integer,	:length => 20
	t.column	:agent_id,	:integer,	:length => 20
	t.column	:server_name,	:string,	:length => 21
	t.column	:start_time,	:datetime
	t.column	:result,	:text
    end
    add_index :dsrresult_logs, :voice_log_id
  end

  def self.down
    drop_table :dsrresult_logs
  end
end
