class CreateKeywordStatistics < ActiveRecord::Migration
  def change
    create_table :keyword_statistics do |t|
      t.integer       :stats_date_id, null: false, foreign_key: false
      t.integer       :stats_id,      null: false, foreign_key: false
      t.integer       :stats_type,    null: false
      t.integer       :keyword_id,    null: false, foreign_key: false
      t.integer       :total,         default: 0
      t.datetime      :updated_at
    end
    add_index :keyword_statistics, [:stats_type, :stats_id, :stats_date_id, :keyword_id], name: 'index_d_report', unique: true
  end
end
