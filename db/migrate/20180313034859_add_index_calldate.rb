class AddIndexCalldate < ActiveRecord::Migration
  def change
    add_index :voice_logs, [:call_date,:agent_id], name: 'index_date_agent'
  end
end
