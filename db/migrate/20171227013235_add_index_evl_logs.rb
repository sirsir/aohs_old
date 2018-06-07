class AddIndexEvlLogs < ActiveRecord::Migration
  def change
    add_index :evaluation_logs, :evaluated_at, name: 'index_edate'
    add_index :evaluation_logs, [:evaluated_by, :evaluated_at], name: 'index_edate_by'
  end
end
