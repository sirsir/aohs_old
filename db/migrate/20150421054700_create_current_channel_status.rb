class CreateCurrentChannelStatus < ActiveRecord::Migration
  def change

    sql =  "CREATE TABLE current_channel_status LIKE voice_logs;"
    execute sql
    
    sql =  "ALTER TABLE current_channel_status ADD connected VARCHAR(20);"
    execute sql

    sql =  "ALTER TABLE current_computer_status ENGINE = MEMORY;"
    execute sql
  
  end
end
