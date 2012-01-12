class ModifiedPrivilegeTbl < ActiveRecord::Migration
  def self.up
    add_column :privileges, :display_group,  :string
    add_column :privileges, :order_no,  :integer
  end

  def self.down
    remove_column :privileges, :display_group
    remove_column :privileges, :order_no
  end
end
