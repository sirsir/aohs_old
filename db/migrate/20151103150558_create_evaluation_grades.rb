class CreateEvaluationGrades < ActiveRecord::Migration
  def change
    create_table :evaluation_grades do |t|
      t.integer     :evaluation_plan_id,  null: false, foreign_key: false
      t.string      :name,                null: false, limit: 25
      t.float       :upper_bound,         null: false, default: 0
      t.float       :lower_bound,         null: false, default: 0
      t.string      :flag,                limit: false
    end
    add_index :evaluation_grades, :evaluation_plan_id, name: 'index_eplan'
  end
end