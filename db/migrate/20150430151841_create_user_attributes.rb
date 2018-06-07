class CreateUserAttributes < ActiveRecord::Migration
  def change
    create_table :user_attributes do |t|
      t.integer     :user_id,     null: false, foreign_key: false
      t.integer     :attr_type,   null: false
      t.string      :attr_val
      t.datetime    :updated_at
    end
    add_index :user_attributes, [:user_id, :attr_type]
  end
end
