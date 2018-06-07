class CreateExportConditions < ActiveRecord::Migration
  def change
    create_table :export_conditions do |t|
      t.integer     :export_task_id,      null: false, foreign_key: false
      t.text        :condition_string,    limit: 16777215
      t.datetime    :created_at
    end
    add_index :export_conditions, :export_task_id
  end
end