# == Schema Information
# Schema version: 20100402074157
#
# Table name: voice_logs_1
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

class VoiceLogTemp < VoiceLog
  set_table_name("voice_logs_1")


#def after_save
#     if self.table_name == "voice_logs_1" or self.table_name == "voice_logs_2"
#       unless self.agent_id.blank? or self.start_time.blank?
#       count_statistic_call(self.agent_id,self.start_time.strftime('%Y-%m-%d'))
#       end
#     end
#end
#
# def count_statistic_call(agent,days)
#       stype = StatisticsType.find(:first,:select => "id",:conditions =>{:target_model => 'VoiceLog' ,:value_type => 'count',:by_agent => 1})
#       unless agent.blank? and days.blank?
#                  if DailyStatistics.exists?({:start_day => days,:agent_id => agent,:statistic_type_id => stype})
#                      before_daily = DailyStatistics.find(:first,:conditions =>{:start_day => days,:agent_id => agent,:statistic_type_id => stype})
#                      before_daily_value = before_daily.value + 1
#                      DailyStatistics.update(before_daily.id,:value => before_daily_value)
#                  else
#                      DailyStatiscs.new(:start_day => days,:agent_id => agent,:statistic_type_id => stype,:value => 1)
#                  end
#         end
# end

end
