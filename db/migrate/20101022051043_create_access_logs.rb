class CreateAccessLogs < ActiveRecord::Migration
  def self.up
    create_table :access_logs do |t|
      t.column  :last_access_time,  :datetime
      t.column  :url,               :string,  :length => 200
      t.column  :count,             :integer
      t.column  :login_name,        :string,  :length => 20
      t.column  :remote_ip,         :string,  :length => 15
      t.column  :mac_address,       :string,  :length => 12          
    end
  end

  def self.down
    drop_table :access_logs
  end
end
