class CreateVoiceLogCars < ActiveRecord::Migration
  def self.up
    create_table :voice_log_cars do |t| 
      t.column  :voice_log_id,  :integer, :limit => 8
      t.column  :car_number_id, :integer
    end
	execute "ALTER TABLE voice_log_cars MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"
	add_index :voice_log_cars, [:voice_log_id,:car_number_id], :name => 'vlcar_index'  
  end
  
  def self.down
    drop_table :voice_log_cars
  end
end
