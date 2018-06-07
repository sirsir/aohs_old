class FixXferLogsField < ActiveRecord::Migration
  def change
    rename_column :xfer_logs, :ext_transfer, :ext_tranfer
    change_column :xfer_logs, :ext_tranfer, :string, limit: 25
  end
end
