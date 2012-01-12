# == Schema Information
# Schema version: 20100402074157
#
# Table name: result_keywords
#
#  id           :integer(20)     not null, primary key
#  start_msec   :integer(10)
#  end_msec     :integer(10)
#  voice_log_id :integer(20)     not null
#  keyword_id   :integer(10)     default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#  edit_status  :string(1)
#

class ResultKeyword < ActiveRecord::Base

   belongs_to :keyword
   belongs_to :voice_log
   named_scope :without_flag,
   lambda {|vid| { :conditions => ['voice_log_id = ? and edit_status != \'d\' or edit_status is null', vid] } }


   def start_sec
      start_msec.to_f / 1000
   end
   def end_sec
      end_msec.to_f / 1000
   end

#   def after_update
#        if self.status == 'e' or self.status == 'd'
#           decrease_statistic_keyword(self.voice_log_id,self.keyword.keyword_type,self.keyword_id)
#                 if self.keyword.keyword_type == 'n'
#                     if VoiceLogCounter.exists?({:voice_log_id => self.voice_log_id})
#                        before_voice_counter  = VoiceLogCounter.find(:first,:select => "id,keyword_count,ngword_count",:conditions =>{:voice_log_id => self.voice_log_id})
#                        after_bookmark_count =  before_voice_counter.ngword_count - 1
#                        after_keyword_count = before_voice_counter.keyword_count - 1
#                        VoiceLogCounter.update(before_voice_counter.id,:ngword_count => after_bookmark_count,:keyword_count => after_keyword_count)
#                     end
#                 elsif self.keyword.keyword_type == 'm'
#                        if VoiceLogCounter.exists?({:voice_log_id => self.voice_log_id})
#                        before_voice_counter  = VoiceLogCounter.find(:first,:select => "id,keyword_count,mustword_count",:conditions =>{:voice_log_id => self.voice_log_id})
#                        after_bookmark_count =  before_voice_counter.must_count - 1
#                        after_keyword_count = before_voice_counter.keyword_count - 1
#                        VoiceLogCounter.update(before_voice_counter.id,:mustword_count => after_bookmark_count,:keyword_count => after_keyword_count)
#                     end
#                 end
#        end
#   end
#
#   def count_statistic_keyword(vid,ktype,kid)
#         stype = StatisticsType.find(:first,:select => "id",:conditions => {:target_model => 'ResultKeyword',:value_type => 'sum',:by_agent => 0}).id
#         agent =  nil
#         s_time = nil
#         stype2 = nil
#         if VoiceLogTemp.exists?(vid)
#            vl = VoiceLogTemp.find(vid)
#            agent = vl.agent_id unless vl.agent_id.nil?
#            s_time = vl.start_time.strftime("%Y-%m-%d") unless vl.start_time.nil?
#            unless s_time.blank?
#            unless agent.blank? or agent == 0
#                if DailyStatistics.exists?({:agent_id => agent,:start_day => s_time,:statistic_type_id => stype})
#                   before_daily = DailyStatistics.find(:first,:conditions =>{:agent_id => agent,:start_day => s_time,:statistic_type_id => stype})
#                   daily_value = before_daily.value + 1
#                   DailyStatistics.update(before_daily.id,:value => daily_value)
#                else
#                  da = DailyStatistics.new(:value => 1,:start_day => s_time,:statistic_type_id => stype,:agent_id => agent)
#                  da.save!
#                end
#            end
#             unless ktype.blank?
#                   case ktype
#                   when 'n'
#                      stype2 =   StatisticsType.find(:first,:select=>"id",:conditions => {:target_model => 'ResultKeyword',:value_type => 'sum:n'}).id
#                   when 'm'
#                       stype2 =   StatisticsType.find(:first,:select=>"id",:conditions => {:target_model => 'ResultKeyword',:value_type => 'sum:m'}).id
#                   when 'a'
#                       stype2 =   StatisticsType.find(:first,:select=>"id",:conditions => {:target_model => 'ResultKeyword',:value_type => 'sum:a'}).id
#                   end
#                   unless kid.blank?
#                   if DailyStatistics.exists?({:keyword_id => kid,:start_day => s_time,:statistic_type_id => stype2})
#                   before_daily = DailyStatistics.find(:first,:conditions =>{:agent_id => agent,:start_day => s_time,:statistic_type_id => stype2})
#                   daily_value = before_daily.value + 1
#                   DailyStatistics.update(before_daily.id,:value => daily_value)
#                   else
#                   da = DailyStatistics.new(:value => 1,:start_day => s_time,:statistic_type_id => stype,:keyword_id => kid)
#                   da.save!
#                   end
#                   end
#             end
#         end
#         end
#   end
#
#   def  decrease_statistic_keyword(vid,ktype,kid)
#         stype = StatisticsType.find(:first,:select => "id",:conditions => {:target_model => 'ResultKeyword',:value_type => 'sum',:by_agent => 0}).id
#         agent =  nil
#         s_time = nil
#         stype2 = nil
#         if VoiceLogTemp.exists?(vid)
#            vl = VoiceLogTemp.find(vid)
#            agent = vl.agent_id unless vl.agent_id.nil?
#            s_time = vl.start_time.strftime("%Y-%m-%d") unless vl.start_time.nil?
#            unless s_time.blank?
#            unless agent.blank? or agent == 0
#                if DailyStatistics.exists?({:agent_id => agent,:start_day => s_time,:statistic_type_id => stype})
#                   before_daily = DailyStatistics.find(:first,:conditions =>{:agent_id => agent,:start_day => s_time,:statistic_type_id => stype})
#                   daily_value = before_daily.value - 1
#                   DailyStatistics.update(before_daily.id,:value => daily_value)
#                end
#            end
#             unless ktype.blank?
#                   case ktype
#                   when 'n'
#                      stype2 =   StatisticsType.find(:first,:select=>"id",:conditions => {:target_model => 'ResultKeyword',:value_type => 'sum:n'}).id
#                   when 'm'
#                       stype2 =   StatisticsType.find(:first,:select=>"id",:conditions => {:target_model => 'ResultKeyword',:value_type => 'sum:m'}).id
#                   when 'a'
#                       stype2 =   StatisticsType.find(:first,:select=>"id",:conditions => {:target_model => 'ResultKeyword',:value_type => 'sum:a'}).id
#                   end
#                   unless kid.blank?
#                   if DailyStatistics.exists?({:keyword_id => kid,:start_day => s_time,:statistic_type_id => stype2})
#                   before_daily = DailyStatistics.find(:first,:conditions =>{:agent_id => agent,:start_day => s_time,:statistic_type_id => stype2})
#                   daily_value = before_daily.value - 1
#                   DailyStatistics.update(before_daily.id,:value => daily_value)
#                   end
#                   end
#             end
#         end
#         end
#   end

end


 #   def after_save
#     if self.id_was.blank?
#        unless self.keyword_id.blank?
#        if self.edit_status != 'n' or self.edit_status.nil?
#           unless self.keyword_id.blank?
#                 count_statistic_keyword(self.voice_log_id,self.keyword.keyword_type,self.keyword_id)
#                 if self.keyword.keyword_type == 'n'
#                      #  STDERR.puts 'new record found'
#                     if VoiceLogCounter.exists?({:voice_log_id => self.voice_log_id})
#                      #   STDERR.puts 'update counter'
#                        before_voice_counter  = VoiceLogCounter.find(:first,:select => "id,keyword_count,ngword_count",:conditions =>{:voice_log_id => self.voice_log_id})
#                        after_bookmark_count =  before_voice_counter.ngword_count + 1
#                        after_keyword_count = before_voice_counter.keyword_count + 1
#                        VoiceLogCounter.update(before_voice_counter.id,:ngword_count => after_bookmark_count,:keyword_count => after_keyword_count)
#                     else
#                       # STDERR.puts 'add new counter'
#                        new_voice_counter = VoiceLogCounter.new(:keyword_count => 1,:ngword_count => 1,:mustword_count => 0,
#                                                          :bookmark_count => 0)
#                        new_voice_counter.save!
#                     end
#                 elsif self.keyword.keyword_type == 'm'
#                        if VoiceLogCounter.exists?({:voice_log_id => self.voice_log_id})
#                      #   STDERR.puts 'update counter'
#                        before_voice_counter  = VoiceLogCounter.find(:first,:select => "id,keyword_count,mustword_count",:conditions =>{:voice_log_id => self.voice_log_id})
#                        after_bookmark_count =  before_voice_counter.must_count + 1
#                        after_keyword_count = before_voice_counter.keyword_count + 1
#                        VoiceLogCounter.update(before_voice_counter.id,:mustword_count => after_bookmark_count,:keyword_count => after_keyword_count)
#                     else
#                       # STDERR.puts 'add new counter'
#                        new_voice_counter = VoiceLogCounter.new(:keyword_count => 1,:ngword_count => 0,:mustword_count => 1,
#                                                          :bookmark_count => 0)
#                        new_voice_counter.save!
#                     end
#                 end
#           end
#         elsif self.edit_status == 'e' or self.edit_status == 'd'
#                decrease_statistic_keyword(self.voice_log_id,self.keyword.keyword_type,self.keyword_id)
#                 if self.keyword.keyword_type == 'n'
#                      #  STDERR.puts 'new record found'
#                     if VoiceLogCounter.exists?({:voice_log_id => self.voice_log_id})
#                      #   STDERR.puts 'update counter'
#                        before_voice_counter  = VoiceLogCounter.find(:first,:select => "id,keyword_count,ngword_count",:conditions =>{:voice_log_id => self.voice_log_id})
#                        after_bookmark_count =  before_voice_counter.ngword_count - 1
#                        after_keyword_count = before_voice_counter.keyword_count - 1
#                        VoiceLogCounter.update(before_voice_counter.id,:ngword_count => after_bookmark_count,:keyword_count => after_keyword_count)
#                     end
#                 elsif self.keyword.keyword_type == 'm'
#                        if VoiceLogCounter.exists?({:voice_log_id => self.voice_log_id})
#                        before_voice_counter  = VoiceLogCounter.find(:first,:select => "id,keyword_count,mustword_count",:conditions =>{:voice_log_id => self.voice_log_id})
#                        after_bookmark_count =  before_voice_counter.must_count - 1
#                        after_keyword_count = before_voice_counter.keyword_count - 1
#                        VoiceLogCounter.update(before_voice_counter.id,:mustword_count => after_bookmark_count,:keyword_count => after_keyword_count)
#                     end
#                 end
#         end
#        end
#     end
#   end
