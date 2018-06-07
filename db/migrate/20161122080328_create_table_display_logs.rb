class CreateTableDisplayLogs < ActiveRecord::Migration
  def change
    create_table :display_logs do |t|
      t.integer     :site_id,           foreign_key: false
      t.integer     :device_id,         foreign_key: false
      t.integer     :channel_id,        foreign_key: false
      t.integer     :system_id,         foreign_key: false
      t.integer     :call_reference
      t.string      :extension,         limit: 20
      t.string      :call_direction,    limit: 10
      t.datetime    :display_time
      t.string      :number1,           limit: 50
      t.string      :number2,           limit: 50
      t.string      :transfer,          limit: 25
      t.string      :busy,              limit: 25
      t.string      :hasduration,       limit: 25
      t.string      :call_id,           limit: 50, foreign_key: false
      t.datetime    :answer_time
      t.string      :monitor,           limit: 25, foreign_key: false
    end
    add_index :display_logs, :call_id, name: 'index_call'
  end
end