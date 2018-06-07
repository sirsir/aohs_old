class AddRaiseByField < ActiveRecord::Migration
  def change
    add_column :evaluation_doc_attachments, :created_by, :integer
    add_column :evaluation_doc_attachments, :updated_by, :integer
  end
end
