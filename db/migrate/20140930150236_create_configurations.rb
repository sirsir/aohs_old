class CreateConfigurations < ActiveRecord::Migration
  def change
    create_table :configurations do |t|
      t.string      :variable,      null: false, limit: 80
      t.string      :desc,          default: ""
      t.string      :value_type,    null: false, default: "string", limit: 100
      t.integer     :configuration_group_id, foreign_key: false 
    end
    add_index :configurations, [:configuration_group_id, :variable], unique: true, name: "index_group_var"
    add_index :configurations, [:configuration_group_id], name: "index_group"
  end
end
