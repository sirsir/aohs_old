class CreateUserActivities < ActiveRecord::Migration
  def self.up
    create_table :user_activities do |t|
      t.column  :start_time,  :datetime
      t.column  :duration,    :integer
      t.column  :process_name,:string,  :length => 200
      t.column  :window_title,:string,  :length => 200
      t.column  :login_name,  :string,  :length => 20
      t.column  :remote_ip,   :string,  :length => 20
      t.column  :mac_address, :string,  :length => 12
    end
  end

  def self.down
    drop_table :user_activities
  end
end
