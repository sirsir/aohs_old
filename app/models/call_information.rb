class CallInformation < ActiveRecord::Base
  
  belongs_to    :voice_log

  scope :of_voicelog, ->(id){
    where(voice_log_id: id).order(:start_msec)  
  }

  def self.result_log(raw)
    
    rs = []
    raw.each do |r|
      d = {
        type:     "event",
        title:    "Info",
        ssec:     r.start_sec,
        stime:    StringFormat.format_sec(r.start_sec),
        result:   r.event_name
      }
      rs << d
    end
    
    return rs

  end
  
  def start_sec
    
    self.start_msec.to_i/1000  
  
  end
  
  def end_sec
    
    self.end_msec.to_i/1000
    
  end
  
  def display_time
    
    times = [
      StringFormat.format_sec(start_sec),
      StringFormat.format_sec(end_sec)
    ]
    
    times.join("-")
    
  end

  def event_name
    
    return self.event
  
  end
  
end
