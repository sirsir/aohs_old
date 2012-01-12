class ChangeThisdnOthertd < ActiveRecord::Migration
  def self.up
    remove_column :call_informations, :this_dn
    remove_column :call_informations, :other_dn

    add_column  :call_informations, :agent_id, :integer
  end

  def self.down
    remove_column  :call_informations, :agent_id
    
    add_column :call_informations, :this_dn, :string
    add_column :call_informations, :other_dn, :string
  end
end
