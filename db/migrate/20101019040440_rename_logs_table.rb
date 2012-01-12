class RenameLogsTable < ActiveRecord::Migration
  def self.up
    rename_table :current_computer_statuses, :current_computer_status
    rename_table :logs, :operation_logs
  end

  def self.down
    rename_table :current_computer_status,:current_computer_statuses 
    rename_table :operation_logs, :logs   
  end
  
end
