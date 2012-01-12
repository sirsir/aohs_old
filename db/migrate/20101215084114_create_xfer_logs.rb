class CreateXferLogs < ActiveRecord::Migration
  def self.up
    create_table :xfer_logs do |t|
      t.column  :start_time,    :datetime
      t.column  :ani,           :string, :limit => 45
      t.column  :dnis,          :string, :limit => 45
      t.column  :call_id1,      :string, :limit => 50
      t.column  :call_id2,      :string, :limit => 50
      t.column  :updated_on,    :datetime
    end
  end

  def self.down
    drop_table :xfer_logs
  end
end
