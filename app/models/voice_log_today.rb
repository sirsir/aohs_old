# == Schema Information
# Schema version: 20100402074157
#
# Table name: voice_logs_today_1
#
#  id             :integer(20)     not null, primary key
#  system_id      :integer(10)
#  device_id      :integer(10)
#  channel_id     :integer(10)
#  ani            :string(30)
#  dnis           :string(30)
#  extension      :string(30)
#  duration       :integer(10)
#  hangup_cause   :integer(10)
#  call_reference :integer(10)
#  agent_id       :integer(10)
#  voice_file_url :string(300)
#  call_direction :string(1)       default("u")
#  start_time     :datetime
#  digest         :string(255)
#  call_id        :string(255)
#  site_id        :integer(10)
#


class VoiceLogToday < ActiveRecord::Base

  set_table_name("voice_logs_today_1")
  
end
