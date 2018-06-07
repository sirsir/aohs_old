class CreateExportTasks < ActiveRecord::Migration
  def change
    create_table :export_tasks do |t|
      t.string      :name,              null: false, limit: 50
      t.string      :desc
      t.string      :schedule_type,     null: false, limit: 30
      t.string      :category,          limit: 50
      t.string      :filename,          limit: 250
      t.string      :audio_type,        limit: 10
      t.string      :compression_type,  limit: 10
      t.datetime    :start_at
      t.string      :flag,              default: "", limit: 3
      t.datetime    :processed_at 
      t.timestamps  null: false
    end
    add_index :export_tasks, :category
    add_index :export_tasks, :schedule_type
  end
end
