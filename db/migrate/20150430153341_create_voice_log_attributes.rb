class CreateVoiceLogAttributes < ActiveRecord::Migration
  def change
    create_table :voice_log_attributes do |t|
      t.integer     :voice_log_id,    null: false, limit: 8, foreign_key: false
      t.integer     :attr_type,       null: false
      t.string      :attr_val
      t.integer     :updated_by
      t.datetime    :updated_at
    end
    add_index :voice_log_attributes, [:voice_log_id, :attr_type], name: 'index_id_attr_type'
  end
end
