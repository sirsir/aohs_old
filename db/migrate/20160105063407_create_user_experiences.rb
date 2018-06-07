class CreateUserExperiences < ActiveRecord::Migration
  def change
    create_table :user_experiences do |t|
      t.integer     :user_id,           null:false, foreign_key: false
      t.string      :position,          limit: 70
      t.string      :company_name,      limit: 100
      t.integer     :length_work,       null: false, default: 0
      t.string      :description,       limit: 200
      t.datetime    :updated_at
    end
    add_index :user_experiences, :user_id
  end
end
