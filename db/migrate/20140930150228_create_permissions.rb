class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.integer   :role_id,       null: false, foreign_key: false 
      t.integer   :privilege_id,  null: false, foreign_key: false 
      t.timestamps
    end
    add_index :permissions, [:role_id, :privilege_id], unique: true
  end
end
