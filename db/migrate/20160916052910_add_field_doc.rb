class AddFieldDoc < ActiveRecord::Migration
  def change
    add_column  :document_templates, :file_hash, :string,  limit: 200
    add_column  :document_templates, :file_size, :integer, null: false, default: 0
  end
end
