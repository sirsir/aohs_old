class CreateCallClassifications < ActiveRecord::Migration
  def change
    create_table :call_classifications do |t|
      t.integer     :voice_log_id,      null: false,  limit: 8, foreign_key: false
      t.integer     :call_category_id,  null: false,  foreign_key: false
      t.string      :flag,              null: false,  default: "", limit: 1
    end
    add_index :call_classifications, :voice_log_id, name: 'index_vl'
    add_index :call_classifications, [:voice_log_id, :call_category_id], name: 'index_vl_ca'
  end
end