class ReviseEvaluationLogFields < ActiveRecord::Migration
  def change
    
    remove_column :evaluation_logs, :total_score
    remove_column :evaluation_logs, :weighted_score
    
    remove_column :evaluation_score_logs, :score
    remove_column :evaluation_score_logs, :evaluation_score_id
    remove_column :evaluation_score_logs, :evaluation_criteria_id
    
    add_column :evaluation_score_logs, :evaluation_question_id, :integer, foreign_key: false
    add_column :evaluation_score_logs, :question_group_id, :integer, foreign_key: false
    add_column :evaluation_score_logs, :max_score, :float
    add_column :evaluation_score_logs, :actual_score, :float
    add_column :evaluation_score_logs, :answer, :string
    
  end
end
