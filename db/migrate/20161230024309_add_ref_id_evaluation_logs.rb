class AddRefIdEvaluationLogs < ActiveRecord::Migration
  def change
    add_column    :evaluation_logs, :ref_log_id, :integer, foreign_key: false
    remove_column :evaluation_calls, :flag
  end
end
