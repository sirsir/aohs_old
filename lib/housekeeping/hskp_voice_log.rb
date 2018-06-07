module HousekeepingData
  class HskpVoiceLog < Base
    
    MINIMUM_DAYS_TODAY_DELETE = 5
    MINIMUM_DAYS_DELETE = 366
    
    def self.cleanup_voice_log
      
      hvl = HskpVoiceLog.new
      
      hvl.cleanup_voice_log_today
      hvl.cleanup_voice_log
      
    end
    
    def cleanup_voice_log_today
      
      del_date = get_delete_date(:voice_log_today)
      del_count = 0
      
      unless del_date.nil?
        del_count = VoiceLogToday.where(["start_time <= ?",del_date]).count(0)
        if del_count > 0
          result = VoiceLogToday.delete_all(["start_time <= ?",del_date])
        end
      end

      logger.info("Housekeeping Task for voice_logs_today removed #{del_count} records before #{del_date}")
      
    end
    
    def cleanup_voice_log

      del_date = get_delete_date(:voice_log)
      del_count = 0
      
      unless del_date.nil?
        del_count = VoiceLogToday.where(["start_time <= ?",del_date]).count(0)
        if del_count > 0
          del_logs = VoiceLog.select(:id).where(["start_time <= ?",del_date]).all
          del_logs.each do |v|
            del_cond = ["voice_log_id = ?", v.id]
            CallComment.delete_all(del_cond)
            CallTrackingLog.delete_all(del_cond)
            CallFavourite.delete_all(del_cond)
            VoiceLogAttribute.delete_all(del_cond)
            VoiceLogCounter.delete_all(del_cond)
            Tagging.delete_all(["tagged_id = ?",v.id])
            v.delete
          end
        end
      end
      
      logger.info("Housekeeping Task for voice_logs removed #{del_count} records before #{del_date}")
      
    end
    
    private
    
    def get_delete_date(tbl)
      
      del_date = nil
      
      case tbl
      when :voice_log
        keep_days = Settings.logs.voice_log_keep_days.to_i
        if correct_days_set?(keep_days, MINIMUM_DAYS_DELETE)
          del_date = get_del_date(keep_days)
        end
      when :voice_log_today
        keep_days = Settings.logs.today_voicelog_keep_days.to_i
        if correct_days_set?(keep_days, MINIMUM_DAYS_TODAY_DELETE)
          del_date = get_del_date(keep_days)
        end
      end
      
      return del_date
    
    end
    
    def correct_days_set?(va, mi)
      return va.to_i > mi
    end
    
    def get_del_date(va)
      return Date.today - va
    end
    
  end
end