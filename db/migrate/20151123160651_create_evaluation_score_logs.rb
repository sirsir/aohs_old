class CreateEvaluationScoreLogs < ActiveRecord::Migration
  def change
    create_table :evaluation_score_logs do |t|
      t.integer     :evaluation_log_id,               null: false, foreign_key: false
      t.integer     :evaluation_criteria_id,          null: false, foreign_key: false
      t.integer     :evaluation_score_id,             null: false, foreign_key: false
      t.float       :score
      t.float       :weighted_score
      t.string      :comment,                         limit: 180
    end
    add_index :evaluation_score_logs, :evaluation_log_id, name: 'index_evl'
  end
end