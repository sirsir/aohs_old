class CreateGroupMembers < ActiveRecord::Migration
  def change
    create_table :group_members do |t|
      t.integer   :group_id,          foreign_key: false 
      t.integer   :user_id,           foreign_key: false 
      t.string    :member_type,       null: false, limit: 2
      t.timestamps
    end
    add_index :group_members, [:member_type, :user_id]
    add_index :group_members, [:member_type, :group_id]
    add_index :group_members, [:member_type, :group_id, :user_id], unique: true
  end
end
