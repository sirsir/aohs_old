class CreateGroupMemberTypes < ActiveRecord::Migration
  def change
    create_table :group_member_types do |t|
      t.string      :member_type,       null: false
      t.string      :title,             null: false
      t.integer     :order_no,          null: false, default: 0
    end
    add_index :group_member_types, :member_type, name: 'index_memtype'
  end
end
