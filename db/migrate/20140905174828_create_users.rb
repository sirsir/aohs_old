class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string    :login,               null: false, limit: 50
      t.integer   :title_id,            foreign_key: false
      t.string    :full_name_en,        null: false, default: ""
      t.string    :full_name_th,        null: false, default: ""
      t.string    :citizen_id,          null: false, default: "",  limit: 25, foreign_key: false 
      t.string    :employee_id,         null: false, default: "",  limit: 25, foreign_key: false 
      t.string    :sex,                 null: false, default: "u", limit: 5
      t.integer   :role_id,             null: false, foreign_key: false 
      t.string    :state,               null: false, limit: 3
      t.date      :joined_date
      t.date      :resign_date
      t.date      :dob
      t.string    :flag,                limit: 1
      t.datetime  :deleted_at
      t.timestamps
    end
    add_index :users, :login,         unique: true
    add_index :users, :flag
    add_index :users, :role_id
    add_index :users, :employee_id
    add_index :users, :citizen_id
    add_index :users, :state
  end
end