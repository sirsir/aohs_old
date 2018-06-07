class AddUpdateInfoCallclass < ActiveRecord::Migration
  def change
    add_column :call_classifications, :updated_at, :datetime
    add_column :call_classifications, :updated_by, :integer
    #add_index :call_classifications, :voice_log_id, name: 'index_voice_log'
    add_index :call_classifications, :call_category_id, name: 'index_call_cate'
  end
end
