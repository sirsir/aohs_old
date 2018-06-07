class ReviseEvaluationCriteria2 < ActiveRecord::Migration
  def change
    add_column :evaluation_criteria, :question_group_id, :integer, foreign_key: false
  end
end
