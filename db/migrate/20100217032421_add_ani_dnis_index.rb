class AddAniDnisIndex < ActiveRecord::Migration
  def self.up
    add_index :voice_logs,  :ani
    add_index :voice_logs,  :dnis
  end

  def self.down
    remove_index :voice_logs,  :ani
    remove_index :voice_logs,  :dnis    
  end
end
