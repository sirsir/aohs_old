class CreateAutoAssessmentSettings < ActiveRecord::Migration
  def change
    create_table :auto_assessment_settings do |t|
      t.integer     :evaluation_plan_id,        foreign_key: false, null: false, default: 0
      t.text        :setting_string             
      t.string      :flag,                      limit: 1, null: false, default: ""
      t.timestamps null: false
    end
  end
end
