class CreateConfigurationTrees < ActiveRecord::Migration
  def change
    create_table :configuration_trees do |t|
      t.integer     :node_id,     null: false,  foreign_key: false
      t.string      :node_type,   null: false,  limit: 30
      t.integer     :parent_id,   default: 0,   foreign_key: false
      t.integer     :configuration_group_id,    foreign_key: false
    end
    add_index :configuration_trees, :parent_id
    add_index :configuration_trees, [:node_id, :node_type], name: 'index_id_node_type'
  end
end
