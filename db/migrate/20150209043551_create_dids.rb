class CreateDids < ActiveRecord::Migration
  def change
    create_table :dids do |t|
      t.string        :number,        null: false, limit: 20
      t.integer       :extension_id,  null: false, foreign_key: false   
      t.timestamps    null: false
    end
    add_index  :dids, :number
    add_index  :dids, :extension_id
  end
end
