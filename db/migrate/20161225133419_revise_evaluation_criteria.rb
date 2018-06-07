class ReviseEvaluationCriteria < ActiveRecord::Migration
  def change
    # evaluation_plan_id
    # name
    # item_type
    # flag
    # order_no
    # parent_id
    # weighted_score
    # created_at
    # updated_at
    # variable_name
    remove_column :evaluation_criteria, :score_type
    remove_column :evaluation_criteria, :total_score
    remove_column :evaluation_criteria, :na_flag
    remove_column :evaluation_criteria, :use_flag
    remove_column :evaluation_criteria, :analytic_template_id
    remove_column :evaluation_criteria, :level_no
    add_column :evaluation_criteria, :evaluation_question_id, :integer, foreign_key: false
    add_column :evaluation_criteria, :revision_no, :integer
  end
end
