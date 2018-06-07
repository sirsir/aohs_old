class CreateAutoAssessmentRules < ActiveRecord::Migration
  def change
    create_table :auto_assessment_rules do |t|
      t.string        :name,            limit: 100
      t.string        :display_name,    limit: 100
      t.string        :rule_type,       limit: 100
      t.text          :rule_options,    limit: 16.megabytes - 1
      t.string        :flag,            limit: 3
      t.timestamps null: false
    end
  end
end
