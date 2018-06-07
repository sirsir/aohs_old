class AddRevScoreLogs < ActiveRecord::Migration
  def change
    add_column    :evaluation_score_logs, :revision_no, :integer
  end
end
