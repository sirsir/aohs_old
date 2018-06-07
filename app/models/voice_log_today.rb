class VoiceLogToday < VoiceLog
  
  self.table_name = 'voice_logs_today'
  
  scope :not_today, ->{
    now = Time.now.beginning_of_day("Y%-%m-%d 00:00:00")
    where(["start_time < ?",now])
  }
  
  def cleanup_all
    # remove all except today
    # VoiceLogToday.not_today.delete_all
  end
  
  def get_transfer
    unless defined? @ds_transcalls
      @ds_transcalls = []
      if self.ori_call_id == '1'
        @ds_transcalls = VoiceLogToday.at_date(self.start_time.to_date).where(ori_call_id: self.call_id).all.to_a
      end
    end
    return @ds_transcalls
  end
  
  # end class
end