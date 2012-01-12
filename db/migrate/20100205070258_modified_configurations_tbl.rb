class ModifiedConfigurationsTbl < ActiveRecord::Migration
  def self.up
    add_column  :configurations, :configuration_group_id, :integer
  end

  def self.down
    remove_column  :configurations, :configuration_group_id
  end
end
