class AddIndexCallsts < ActiveRecord::Migration
  def change
    add_index :current_channel_status, :id, name: 'index_id'
    add_index :current_channel_status, :call_id, name: 'index_call_id'
  end
end
