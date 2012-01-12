class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.datetime :start_time
      t.string :name
      t.string :status
      t.string :target
      t.string :user
	  t.string :remote_ip
    end
  end

  def self.down
    drop_table :logs
  end
end
