class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :name
      t.string :description
	  t.integer :leader_id, :null => false, :default => 0
      t.integer :lock_version
      t.timestamps
    end
  end

  def self.down
    drop_table :groups
  end
end
