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
    (start_msec.to_f / 1000)
  end
  
  def end_sec
    (end_msec.to_f / 1000)
  end

  def bookmark_counter
    
    voice_log_id = self.voice_log_id
    
    bookmarks_count = CallBookmark.count(:id).where({ :voice_log__id => voice_log_id })
    
    vc = VoiceLogCounter.init_voice_log_counter(voice_log_id)
    if vc == true
      vc = VoiceLogCounter.first.where({ :voice_log_id => voice_log_id })
      if vc.bookmark_count != bookmarks_count
        vc.update_attributes({:bookmark_count => bookmarks_count})
      end  
    end
  
  end

  def self.update_bookmarks(voice_log_id,bookmarks=[])
    
    v = VoiceLogTemp.where({:id => voice_log_id })
    
    unless v.nil?
    
      cbs = CallBookmark.where({:voice_log_id => voice_log_id})
      unless cbs.empty?
        cbs.each do |cb|
          
          cb2 = bookmarks.pop
          
          if cb2.nil?
            CallBookmark.destroy(cb.id)
          else
            if (cb.start_msec.to_f) == cb2[:start_time] and 
               (cb.end_msec.to_f == cb2[:end_time]) and 
               (cb.title == cb2[:title]) and 
               (cb.body == cb2[:body])
               #Skip
            else
               #Replace
               CallBookmark.update(cb.id,cb2)
            end            
          end

        end #end cbs

      end
      
      while not bookmarks.empty?
        cb2 = bookmarks.pop
        CallBookmark.create(cb2);
      end
      
      return true
    else
      return false
    end
    
  end
  
end

