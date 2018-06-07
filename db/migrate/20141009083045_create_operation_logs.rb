class CreateOperationLogs < ActiveRecord::Migration
  def change
    create_table :operation_logs do |t|
      t.datetime      :created_at
      # log_type as info, warning, error, ...
      t.string        :log_type
      # module_name as table_name, controller_name, ...
      t.string        :module_name
      # event_type as create, update, delete, ..
      t.string        :event_type
      t.string        :created_by
      t.string        :remote_ip
      t.string        :message
      # hidden info
      t.text          :log_detail
      t.integer       :target_id,     foreign_key: false
      t.string        :target_name
    end
  end
end
