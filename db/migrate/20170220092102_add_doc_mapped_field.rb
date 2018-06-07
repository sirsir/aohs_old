class AddDocMappedField < ActiveRecord::Migration
  def change
    add_column :document_templates, :mapped_fields, :text
  end
end
