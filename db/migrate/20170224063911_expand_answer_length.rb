class ExpandAnswerLength < ActiveRecord::Migration
  def change
    change_column :evaluation_score_logs, :answer, :text
  end
end
