class CreateEvaluationCriteria < ActiveRecord::Migration
  def change
    create_table :evaluation_criteria do |t|
      t.integer     :evaluation_plan_id,  null:false, foreign_key: false
      t.string      :name,                null: false
      t.string      :item_type,           null: false, limit: 30
      t.string      :flag,                null: false, default: "", limit: 1
      t.integer     :order_no,            null: false, default: 0
      t.integer     :level_no,            null: false, default: 0
      t.integer     :parent_id,           null: false, default: 0, foreign_key: false
      t.string      :score_type,          limit: 20
      t.float       :total_score
      t.float       :weighted_score 
      t.timestamps  null: false
    end
    add_index :evaluation_criteria, :evaluation_plan_id, name: 'index_eplan'
  end
end