class AddDigest < ActiveRecord::Migration
  def self.up
    add_column  :voice_logs, :digest,  :string
  end

  def self.down
    remove_column  :voice_logs, :digest,  :string
  end
end
