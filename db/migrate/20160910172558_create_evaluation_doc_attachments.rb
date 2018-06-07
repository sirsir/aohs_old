class CreateEvaluationDocAttachments < ActiveRecord::Migration
  def change
    create_table :evaluation_doc_attachments do |t|
      t.integer       :evaluation_log_id,     null: false, foreign_key: false
      t.integer       :document_template_id,  null: false, foreign_key: false
      t.text          :doc_data,              limit: 64.kilobytes + 1
      t.timestamps                            null: false
    end
    add_index :evaluation_doc_attachments, :evaluation_log_id, name: 'index_evl'
  end
end
