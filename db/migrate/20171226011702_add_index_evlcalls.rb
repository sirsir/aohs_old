class AddIndexEvlcalls < ActiveRecord::Migration
  def change
    add_index :evaluation_calls, [:call_date, :evaluation_log_id], name: 'index_cdate_log'
    add_index :evaluation_logs, [:flag, :id], name: 'index_flg_id'
  end
end
