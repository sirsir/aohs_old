class CreateGroupManagers < ActiveRecord::Migration
  def self.up
    create_table :group_managers do |t|
      t.column  :user_id, :integer
      t.column  :manager_id, :integer   
      t.timestamps
    end
  end

  def self.down
    drop_table :group_managers
  end
end
