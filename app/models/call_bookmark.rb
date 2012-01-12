# == Schema Information
# Schema version: 20100402074157
#
# Table name: call_bookmarks
#
#  id           :integer(20)     not null, primary key
#  voice_log_id :integer(20)     not null
#  start_msec   :integer(10)
#  end_msec     :integer(10)
#  title        :string(255)
#  body         :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

class CallBookmark < ActiveRecord::Base
  
   belongs_to :voice_log

  @del_voice_id = nil

   def start_sec
      start_msec.to_f / 1000
   end
   def end_sec
      end_msec.to_f / 1000
   end

#   def after_save
#    # execute "call sum_voice_log_counter(#{self.voice_log_id},0);"
##    STDERR.puts "voice log is "
##    STDERR.puts self.id
##    STDERR.puts self.voice_log_id_was
# #   STDERR.puts record.voice_log_id
#    if self.voice_log_id_was.blank?
#        #  STDERR.puts 'new record found'
#       if VoiceLogCounter.exists?({:voice_log_id => self.voice_log_id})
#        #   STDERR.puts 'update counter'
#          before_voice_counter  = VoiceLogCounter.find(:first,:select => "id,bookmark_count",:conditions =>{:voice_log_id => self.voice_log_id})
#          after_bookmark_count =  before_voice_counter.bookmark_count + 1
#          VoiceLogCounter.update(before_voice_counter.id,:bookmark_count => after_bookmark_count)
#       else
#         # STDERR.puts 'add new counter'
#          new_voice_counter = VoiceLogCounter.new(:keyword_count => 0,:ngword_count => 0,:mustword_count => 0,
#                                            :bookmark_count => 1)
#          new_voice_counter.save!
#       end
#    end
#    end
#
##     def before_destroy
##       @del_voice_id = self.voice_log_id
##     end
#
#     def after_destroy
#       #   STDERR.puts self.id
#        #  STDERR.puts @del_voice_id
#          if VoiceLogCounter.exists?({:voice_log_id => self.voice_log_id})
#              before_voice_counter  = VoiceLogCounter.find(:first,:select => "id,bookmark_count",:conditions =>{:voice_log_id => self.voice_log_id})
#              after_bookmark_count =  before_voice_counter.bookmark_count - 1
#              VoiceLogCounter.update(before_voice_counter.id,:bookmark_count => after_bookmark_count)
#           end
#     end
    
   end

