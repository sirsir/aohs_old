class CreateVoiceLogAtlusrMaps < ActiveRecord::Migration
  def change
    create_table :voice_log_atlusr_maps, id: false do |t|
      t.integer     :voice_log_id,    null: false, default: 0, limit: 8, foreign_key: false
      t.integer     :user_atl_id,     null: false, default: 0, foreign_key: false
    end
    add_index :voice_log_atlusr_maps, [:voice_log_id,:user_atl_id], name: 'index_vlatl'
  end
end
