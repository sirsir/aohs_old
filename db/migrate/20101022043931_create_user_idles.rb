class CreateUserIdles < ActiveRecord::Migration
  def self.up
    create_table :user_idles do |t|
      t.column  :start_time,  :datetime
      t.column  :duration,    :integer
      t.column  :login_name,  :string,  :length => 20
      t.column  :remote_ip,   :string,  :length => 15
      t.column  :mac_address, :string,  :length => 12
    end
  end

  def self.down
    drop_table :user_idles
  end
end
