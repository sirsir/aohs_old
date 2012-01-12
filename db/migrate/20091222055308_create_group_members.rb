class CreateGroupMembers < ActiveRecord::Migration
  def self.up
    create_table :group_members do |t|
      t.column      :group_id, :integer
      t.column      :user_id,  :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :group_members
  end
end
