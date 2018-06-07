class AddProcessName < ActiveRecord::Migration
  def change
    add_column  :user_activity_logs, :proc_exec_name, :string,  limit: 100
  end
end
