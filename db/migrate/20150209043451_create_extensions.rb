class CreateExtensions < ActiveRecord::Migration
  def change
    create_table :extensions do |t|
      t.string        :number,      null: false, limit: 10
      t.integer       :user_id,     foreign_key: false
      t.integer       :location_id, foreign_key: false
      t.timestamps                  null: false
    end
    add_index :extensions, :number, unique: true
  end
end
