class CreateEvaluationPlans < ActiveRecord::Migration
  def change
    create_table :evaluation_plans do |t|
      t.string      :name,          null: false, limit: 120
      t.string      :description
      t.string      :flag,          null: false, default: "", limit: 1
      t.integer     :revision_no,   null: false, defalult: 0
      t.timestamps  null: false
    end
    add_index :evaluation_plans, :name
  end
end
