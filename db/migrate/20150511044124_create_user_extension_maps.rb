class CreateUserExtensionMaps < ActiveRecord::Migration
  def change
    create_table :user_extension_maps do |t|
      t.string      :extension,     limit: 15
      t.string      :did,           limit: 20
      t.integer     :agent_id,      null: false, foreign_key: false
      t.datetime    :updated_at
    end
    add_index :user_extension_maps, :extension
    add_index :user_extension_maps, :did
    add_index :user_extension_maps, [:agent_id, :extension, :did], name: "index_aed", unique: true
  end
end
