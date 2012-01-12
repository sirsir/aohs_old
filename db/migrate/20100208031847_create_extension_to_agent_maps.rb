class CreateExtensionToAgentMaps < ActiveRecord::Migration
  def self.up
    create_table :extension_to_agent_maps do |t|
      t.column :extension,:string,:limit => 20
      t.column :agent_id,:integer
     # t.timestamps
    end
  end

  def self.down
    drop_table :extension_to_agent_maps
  end
end
