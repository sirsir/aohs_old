class CreateCurrentComputerLogs < ActiveRecord::Migration
  def change
    # table latest_computer_logs
    sql =  "CREATE TABLE current_computer_status LIKE computer_logs"
    execute sql
  end
end
