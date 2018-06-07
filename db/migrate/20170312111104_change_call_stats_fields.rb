class ChangeCallStatsFields < ActiveRecord::Migration
  def change
    remove_index :call_statistics, name: 'index_d_report'
    rename_column :call_statistics, :stats_id, :agent_id
    add_column :call_statistics, :group_id, :integer, foreign_key: false
    add_index :call_statistics, [:stats_type, :agent_id, :stats_date_id], name: 'index_d_report'
  end
end
