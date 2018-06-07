class CreateTelephoneInfos < ActiveRecord::Migration
  def change
    create_table :telephone_infos do |t|
      t.string    :number,        limit: 50
      t.string    :number_type,   limit: 50
    end
    add_index :telephone_infos, :number, name: 'index_number'
  end
end
