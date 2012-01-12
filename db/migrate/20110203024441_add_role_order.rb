class AddRoleOrder < ActiveRecord::Migration
  def self.up
	add_column	:roles,	:order_no,	:integer
  end

  def self.down
  end
end
