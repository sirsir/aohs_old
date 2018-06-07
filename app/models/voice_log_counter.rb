class VoiceLogCounter < ActiveRecord::Base
  
  # type of counter for voice_log
  
  CT_TAGGING    = 1   # taggings
  CT_COMMENT    = 2   # call_comments
  CT_RSKEYWORD  = 3   # result_keywords - all
  CT_NGKEYWORD  = 4   # result_keywords - ng word
  CT_MUKEYWORD  = 5   # result_keywords - must word
  CT_TRFCALL    = 6   # voice_logs - transfer call
  CT_TRFCALLIN  = 7   # voice_logs - transfer call - inbound
  CT_TRFCALLOU  = 8   # voice_logs - transger call - outbound
  CT_FAV        = 9   # favourite call
  CT_CACLASS    = 10  # call classification
  
  belongs_to     :voice_logs
  
  scope :tagging, ->{
    where(counter_type: CT_TAGGING)  
  }
  
  scope :comment, ->{
    where(counter_type: CT_COMMENT)  
  }
  
  scope :ngword, ->{
    where(counter_type: CT_NGKEYWORD)  
  }
  
  scope :mustword, ->{
    where(counter_type: CT_MUKEYWORD)
  }
  
  scope :fav, ->{
    where(counter_type: CT_FAV)
  }
  
  def self.new_ngword_count(p={})
    
    vl = VoiceLogCounter.new(p)
    vl.counter_type = CT_NGKEYWORD
    
    return vl
  
  end

  def self.new_mustword_count(p={})
    
    vl = VoiceLogCounter.new(p)
    vl.counter_type = CT_MUKEYWORD
    
    return vl
  
  end

  def self.fav_count(voice_log_id, n)
    
    cn = {
      voice_log_id: voice_log_id
    }
    
    vc = VoiceLogCounter.fav.where(cn).first
    if vc.nil?
      cn = {
        voice_log_id: voice_log_id,
        counter_type: CT_FAV,
        valu: n.to_i
      }
      vc = VoiceLogCounter.new(cn)
      vc.save unless vc.zero_count?
    else
      vc.valu = n.to_i
      if vc.zero_count?
        vc.delete
      else
        vc.save
      end
    end
    
  end
  
  def record_count
    return self.valu.to_i
  end
  
  def zero_count?
    return (self.valu.to_i <= 0)
  end
  
end
