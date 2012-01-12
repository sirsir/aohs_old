class CreateDidAgentMaps < ActiveRecord::Migration
  def self.up
    create_table :did_agent_maps do |t|
      t.column :number,:string,:limit => 20
      t.column :agent_id,:integer
    end
  end

  def self.down
    drop_table :did_agent_maps
  end
end
