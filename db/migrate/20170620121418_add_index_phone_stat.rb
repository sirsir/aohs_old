class AddIndexPhoneStat < ActiveRecord::Migration
  def change
    add_index :phoneno_statistics, :number, name: 'index_number'
    add_index :phoneno_statistics, :phone_type, name: 'index_number_type'
  end
end
