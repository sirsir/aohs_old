class CreateCallFavourites < ActiveRecord::Migration
  def change
    create_table :call_favourites do |t|
      t.integer     :voice_log_id,    null: false,  limit: 8, foreign_key: false
      t.integer     :user_id,         null: false, foreign_key: false
      t.datetime    :created_at
    end
    add_index   :call_favourites, [:voice_log_id, :user_id], name: 'index_vl_usr'
    add_index   :call_favourites, :voice_log_id, name: 'index_vl'
  end
end