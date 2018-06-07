class CreateUserEducations < ActiveRecord::Migration
  def change
    create_table :user_educations do |t|
      t.integer     :user_id,         null: false, foreign_key: false
      t.integer     :degree
      t.string      :institution,     limit: 120
      t.string      :subject,         limit: 120
      t.integer     :year_passed
      t.datetime    :updated_at
    end
    add_index :user_educations, :user_id
  end
end
