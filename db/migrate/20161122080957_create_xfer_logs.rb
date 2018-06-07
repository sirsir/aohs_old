class CreateXferLogs < ActiveRecord::Migration
  def change
    create_table :xfer_logs do |t|
      t.integer   :xfer_id,         limit: 8, foreign_key: false
      t.datetime  :xfer_start_time
      t.string    :xfer_ani,        limit: 50
      t.string    :xfer_dnis,       limit: 50
      t.string    :xfer_extension,  limit: 50
      t.string    :xfer_call_id1,   limit: 50, foreign_key: false
      t.string    :xfer_call_id2,   limit: 50, foreign_key: false
      t.timestamp :updated_on
      t.string    :msg_type,        limit: 10
      t.string    :ip,              limit: 50
      t.string    :xfer_type,       limit: 20
      t.string    :mapping_status,  limit: 20
      t.string    :sender,          limit: 10
      t.string    :ext_transfer,    limit: 1
    end
    add_index :xfer_logs, :xfer_start_time, name: 'index_xfer1'
    add_index :xfer_logs, [:xfer_extension, :xfer_ani, :xfer_id], name: 'index_xfer2'
  end
end
