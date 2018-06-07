class ReviseEvaluationScores < ActiveRecord::Migration
  def change
    # evaluation_criteria_id
    # name
    # description
    # score
    # order_no
    # flag
    remove_column :evaluation_scores, :name
    remove_column :evaluation_scores, :description
    remove_column :evaluation_scores, :score
    remove_column :evaluation_scores, :order_no
    remove_column :evaluation_scores, :flag
    add_column :evaluation_scores, :answer_type,  :string, limit: 50
    add_column :evaluation_scores, :answer_list,  :text
    add_column :evaluation_scores, :max_score,    :float
  end
end
