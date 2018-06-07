class CreateConfigurationDetails < ActiveRecord::Migration
  def change
    create_table :configuration_details do |t|
      t.integer     :configuration_id,        null: false, foreign_key: false 
      t.integer     :configuration_tree_id,   null: false, foreign_key: false 
      t.string      :conf_value
      t.timestamps
    end
    add_index :configuration_details, [:configuration_id, :configuration_tree_id], name: "index_id_tree"
  end
end