class CreateGroupMemberHistories < ActiveRecord::Migration
  def change
    create_table :group_member_histories do |t|
      t.integer     :group_id,          foreign_key: false 
      t.integer     :user_id,           foreign_key: false 
      t.string      :member_type,       null: false, limit: 2
      t.string      :display_name,      limit: 100
      t.datetime    :created_date,      null: false, default: 0
      t.datetime    :deleted_date,      null: false, default: 0
    end
    add_index :group_member_histories, [:member_type, :user_id, :created_date, :deleted_date], name: "index_mem1"
    add_index :group_member_histories, [:member_type, :user_id], name: 'index_mem2'
  end
end
