class AddLeaderFields < ActiveRecord::Migration
  def change
    add_column :evaluation_logs, :supervisor_id, :integer, foreign_key: false
    add_column :evaluation_logs, :chief_id, :integer, foreign_key: false
  end
end
