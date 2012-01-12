class CreateConfigurationGroups < ActiveRecord::Migration
  def self.up
    create_table :configuration_groups do |t|
      t.column  :name, :string, :limit => 100
      t.column  :configuration_type, :string, :limit => 1
      t.timestamps
    end
  end

  def self.down
    drop_table :configuration_groups
  end
  
end
