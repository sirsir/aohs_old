class AddColAttachment < ActiveRecord::Migration
  def change
    add_column  :evaluation_doc_attachments, :flag, :string,  limit: 1, null: false, default: ""
  end
end
