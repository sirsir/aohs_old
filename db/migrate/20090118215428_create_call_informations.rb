class CreateCallInformations < ActiveRecord::Migration
  def self.up
    create_table :call_informations do |t|
      t.integer :voice_log_id, :null => false
      t.integer :start_msec
      t.integer :end_msec
      t.string :event
      t.string :this_dn
      t.string :other_dn

      t.timestamps
    end
  end

  def self.down
    drop_table :call_informations
  end
end
