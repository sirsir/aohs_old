class ChangeResultLogLength < ActiveRecord::Migration
  def change
    change_column :auto_assessment_logs, :result_log, :text
  end
end
