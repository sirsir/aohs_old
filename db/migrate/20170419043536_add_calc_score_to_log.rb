class AddCalcScoreToLog < ActiveRecord::Migration
  def change
    add_column :evaluation_logs, :score, :float
    add_column :evaluation_logs, :weighted_score, :float
  end
end
