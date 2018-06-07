class AddFieldPlanId < ActiveRecord::Migration
  def change
    add_column :evaluation_question_stats, :evaluation_plan_id, :integer
  end
end
