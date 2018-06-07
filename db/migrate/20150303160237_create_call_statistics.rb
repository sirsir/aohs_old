class CreateCallStatistics < ActiveRecord::Migration
  def change
    create_table :call_statistics do |t|
      t.integer       :stats_date_id, null: false, foreign_key: false
      t.integer       :stats_id,      null: false, foreign_key: false
      t.integer       :stats_type,    null: false
      t.integer       :total,         default: 0
      t.datetime      :updated_at
    end
    add_index :call_statistics, [:stats_type, :stats_id, :stats_date_id], name: 'index_d_report', unique: true
    add_index :call_statistics, [:stats_date_id, :stats_type], name: 'index_d_report2'
    add_index :call_statistics, [:stats_type, :stats_date_id], name: 'index_d_report3' 
  end
end