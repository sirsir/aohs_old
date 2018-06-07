class EvaluationCall < ActiveRecord::Base
  
  belongs_to  :evaluation_log
  belongs_to  :voice_log
  
  scope :find_evaluated_call, ->(f,v){
    cond = {
      evaluation_plan_id: f,
      voice_log_id: v
    }
    where(cond)  
  }
  
  scope :find_logs, ->(f,l){
    cond = {
      evaluation_plan_id: f,
      evaluation_log_id: l
    }
    where(cond)
  }
  
  def start_time
    return [
      self.call_date.strftime("%Y-%m-%d"),
      self.call_time.strftime("%H:%M:%S")
    ].join(" ")
  end
  
  def start_time_v2
    return [
      self.call_date.strftime("%Y%m%d"),
      self.call_time.strftime("%H%M%S")
    ].join("_")
  end
  
  def update_call_info
    v = VoiceLog.where(id: self.voice_log_id).first
    unless v.nil?
      self.call_date = v.start_time.strftime("%Y-%m-%d")
      self.call_time = v.start_time.strftime("%H:%M:%S")
      self.ani = v.ani
      self.dnis = v.dnis
      self.duration = v.duration
    end
  end
  
end
