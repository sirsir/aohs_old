class CreateEvaluationGradeSettings < ActiveRecord::Migration
  def change
    create_table :evaluation_grade_settings do |t|
      t.string        :title
      t.string        :flag,          limit: 1
      t.timestamps    null: false
    end
    add_column :evaluation_grades, :evaluation_grade_setting_id, :integer, foreign_key: false
    add_column :evaluation_plans, :evaluation_grade_setting_id, :integer, foreign_key: false
  end
end
