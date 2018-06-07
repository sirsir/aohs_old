class CreateExportLogs < ActiveRecord::Migration
  def change
    create_table :export_logs do |t|
      t.integer           :export_task_id,    null: false,  foreign_key: false
      t.text              :condition_string,  limit: 16777215
      t.date              :target_call_date
      t.string            :status,            limit: 3
      t.string            :flag,              limit: 3
      t.text              :result_string      
      t.string            :digest_string,     limit: 45
      t.integer           :retry_count,       null: false, default: 0
      t.timestamps        null: false
    end
    add_index :export_logs, :export_task_id, name: 'index_task'
  end
end