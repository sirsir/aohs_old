class AddOperatorId < ActiveRecord::Migration
  
  def self.up
    add_column  :users, :cti_agent_id,  :integer
    add_index :users, :cti_agent_id
  end

  def self.down
    remove_index :users, :cti_agent_id
    remove_column  :users, :cti_agent_id
  end

end
