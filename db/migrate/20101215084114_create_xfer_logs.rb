class CreateXferLogs < ActiveRecord::Migration
  def self.up
    create_table :xfer_logs do |t|
      t.column  :xfer_start_time,    :datetime
      t.column  :xfer_ani,           :string,  :limit => 45
      t.column  :xfer_dnis,          :string,  :limit => 45
      t.column  :xfer_extension,     :string,  :limit => 45
      t.column  :xfer_call_id1,      :string,  :limit => 50
      t.column  :xfer_call_id2,      :string,  :limit => 50
      t.column  :updated_on,    :datetime
      t.column  :msg_type,      :string,  :limit => 10
      t.column  :xfer_type,     :string,  :limit => 20
      t.column  :mapping_status,:integer, :limit => 1
      t.column  :sender,        :string,  :limit => 10
      t.column  :ip,            :string,  :limit => 20
    end
  end

  def self.down
    drop_table :xfer_logs
  end
end
