class ExpandLogResult < ActiveRecord::Migration
  def change
    change_column :auto_assessment_logs, :result_log, :text, limit: 16.megabytes - 1 
  end
end
