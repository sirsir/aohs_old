class CreateEvaluationLogs < ActiveRecord::Migration
  def change
    create_table :evaluation_logs do |t|
      t.integer       :evaluation_plan_id,      null: false, foreign_key: false
      t.integer       :user_id,                 null: false, foreign_key: false
      t.integer       :group_id,                foreign_key: false
      t.float         :total_score,             null: false, default: 0
      t.float         :weighted_score,          null: false, default: 0
      t.integer       :evaluated_by,            null: false
      t.datetime      :evaluated_at
      t.integer       :updated_by   
      t.datetime      :updated_at
      t.integer       :checked_by
      t.datetime      :checked_at
      t.string        :checked_result,         limit: 1
      t.string        :flag,                   null: false, default: '', limit: 1
      t.integer       :revision_no,            null: false, default: 0
    end
    add_index :evaluation_logs, :evaluation_plan_id, name: 'index_eplan'
    add_index :evaluation_logs, :user_id, name: 'index_usr'
  end
end
