class AddCallDateToVl < ActiveRecord::Migration
  def change
    add_column  :voice_logs, :call_date, :date
  end
end
