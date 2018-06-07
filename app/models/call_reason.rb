class CallReason < ActiveRecord::Base
  
  belongs_to    :voice_logs
  
  scope :by_voice_log, ->(id){
    where({ voice_log_id: id })
  }

  def self.result_log(raw)
    
    rs = []
    raw.each do |r|
      rs << {
        title:  r.title
      }
    end
    
    return rs
  
  end

end
