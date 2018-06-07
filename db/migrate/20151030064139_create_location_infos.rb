class CreateLocationInfos < ActiveRecord::Migration
  def change
    create_table :location_infos do |t|
      t.string      :name,        null: false,  limit: 50
      t.string      :code_name,   limit: 20
      t.string      :flag,        limit: 1, default: ''
      t.timestamps  null: false
    end
  end
end
