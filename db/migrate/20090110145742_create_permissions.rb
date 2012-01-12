class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.integer :role_id
      t.integer :privilege_id
      t.integer :lock_version

      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end
