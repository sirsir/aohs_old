class CreateConfigurationGroups < ActiveRecord::Migration
  def change
    create_table :configuration_groups do |t|
      t.string      :name,    null: false, limit: 80
      t.string      :desc,    default: ""
      t.timestamps
    end
    add_index :configuration_groups, :name, unique: true
  end
end
