class CreateLoggerChannels < ActiveRecord::Migration
  def change
    create_table :logger_channels, id: false do |t|
      t.integer     :site_id,       null: false, foreign_key: false
      t.integer     :system_id,     null: false, foreign_key: false
      t.integer     :device_id,     null: false, foreign_key: false
      t.integer     :channel_id,    null: false, foreign_key: false
      t.integer     :user_id,       null: false, default: 0, foreign_key: false
      t.string      :extension,     null: false, default: '', limit: 10
      t.string      :phone_number,  limit: 50
      t.string      :call_id,       limit: 50, foreign_key: false
      t.string      :status,        limit: 25
    end
    add_index :logger_channels, [:site_id, :system_id, :device_id, :channel_id], name: 'index_ssdc'
  end
end
