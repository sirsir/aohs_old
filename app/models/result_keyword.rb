class ResultKeyword < ActiveRecord::Base
  
  belongs_to    :voice_log
  belongs_to    :keyword
  
  scope :of_voicelog, ->(id){
    where(voice_log_id: id)  
  }
  
  def self.result_logs(raw)
    rs = []
    ls = []
    raw.each_with_index do |rk,i|    
      kw = rk.keyword_info
      next if kw.keyword_type.nil?
      rs << {
        no: i+1,
        id: rk.id,
        dsp_stime: rk.display_stime_in_hhmm,
        start_sec: rk.start_sec,
        end_sec: rk.end_sec,
        channel: rk.channel_no,
        text: rk.result,
        type: kw.keyword_type.name
      }
      ls[rk.channel_no.to_i] = [] if ls[rk.channel_no.to_i].nil?
      ls[rk.channel_no.to_i] << { text: rk.result, css_class: kw.css_content_class}
    end
    
    ls.each {|x| x = x.uniq }
    
    return {
      keywords: rs,
      list: ls 
    }
  end
  
  def display_stime  
    return self.start_msec
  end
  
  def display_stime_in_hhmm
    return StringFormat.format_sec(display_stime/1000)
  end
  
  def start_sec
    return self.start_msec/1000.0
  end
  
  def end_sec
    return self.end_msec/1000.0
  end
  
  def channel_no
    return self.channel.to_i  
  end
  
  def keyword_info
    @keyword = self.keyword  
    unless @keyword.nil?
      return @keyword
    end
    return Keyword.new
  end
  
end
