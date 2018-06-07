class ReviseEvaluationFormFields < ActiveRecord::Migration
  def change
    add_column :evaluation_plans, :rules, :text
    remove_column :document_templates, :evaluation_plan_id
  end
end
