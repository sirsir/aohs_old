class CreateDocumentTemplates < ActiveRecord::Migration
  def change
    create_table :document_templates do |t|
      t.string        :title,               null: false, limit: 150
      t.string        :description
      t.integer       :evaluation_plan_id,  null: false, default: 0, foreign_key: false
      t.binary        :file_data,           limit: 16.megabyte
      t.string        :flag,                null: false, default: ""
      t.string        :file_path,           limit: 100
      t.string        :file_type,           limit: 10
      t.timestamps                          null: false
    end
    add_index :document_templates, :evaluation_plan_id, name: 'index_eplan'
  end
end