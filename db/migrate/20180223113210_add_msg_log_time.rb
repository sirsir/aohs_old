class AddMsgLogTime < ActiveRecord::Migration
  def change
    add_column :message_logs, :start_msec, :integer
    add_column :message_logs, :end_msec, :integer
    add_column :message_logs, :dsr_ut_ended_at, :datetime
    add_column :message_logs, :dsr_rs_created_at, :datetime
    add_column :message_logs, :dsr_rs_accepted_at, :datetime
  end
end
