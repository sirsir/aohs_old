class AddReportTitle < ActiveRecord::Migration
  def change
    add_column :evaluation_questions, :report_title, :string
    add_column :evaluation_question_groups, :report_title, :string
    # add comment option
    add_column :evaluation_plans, :comment_flag, :string, limit: 3
  end
end
