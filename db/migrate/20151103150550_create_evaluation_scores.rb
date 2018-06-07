class CreateEvaluationScores < ActiveRecord::Migration
  def change
    create_table :evaluation_scores do |t|
      t.integer        :evaluation_criteria_id,   null: false, foreign_key: false
      t.string         :name,                     null: false, limit: 120
      t.string         :description,              limit: 150
      t.float          :score
      t.integer        :order_no
      t.string         :flag,                     null: false, default: ""
    end
    add_index :evaluation_scores, :evaluation_criteria_id, name: 'index_ecrit'
  end
end
