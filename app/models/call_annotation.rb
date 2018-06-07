class CallAnnotation < ActiveRecord::Base
  
  # ANNOTATION TYPE FOR CALL
  # Field annot_type
  
  TYPE_EVENT      = 'EVENT'
  TYPE_HOLD       = 'HOLD'
  TYPE_UNHOLD     = 'UNHOLD'
  TYPE_TRANSFER   = 'TRF'
  TYPE_CONFERENCE = 'CONF'
  TYPE_BOOKMARK   = 'BM'
  
  belongs_to    :voice_logs
  
  scope :by_voice_log, ->(id){
    where({ voice_log_id: id }).order_by_default
  }
  
  scope :by_type, ->(types){
    where({ annot_type: types })  
  }
  
  scope :only_call_events, ->{
    by_type([TYPE_HOLD, TYPE_UNHOLD, TYPE_EVENT])
  }
  
  scope :only_bookmark, ->{
    by_type([TYPE_BOOKMARK])  
  }
  
  scope :order_by_default, ->{
    order(:start_msec)
  }
  
  def self.result_log(raw)
    
    rets = []
    raw.each do |r|
      rets << {
        type:   r.type_name,
        ssec:   r.start_sec,
        esec:   r.end_sec,
        stime:  StringFormat.format_sec(r.start_sec),
        title:  r.title
      }
    end
    
    return rets
  
  end
  
  def start_sec
    return msec_to_sec(self.start_msec)  
  end
  
  def end_sec
    return msec_to_sec(self.end_msec)
  end

  def type_name
    
    case self.annot_type
    when TYPE_BOOKMARK
      return "bookmark"
    when TYPE_HOLD, TYPE_UNHOLD
      return "event"
    end
    
    return self.annot_type.to_s.downcase
  
  end
  
  private
  
  def msec_to_sec(msec)
    return msec.to_f/1000.0
  end

end
