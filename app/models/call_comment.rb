class CallComment < ActiveRecord::Base
  
  belongs_to    :user,          foreign_key: 'created_by'
  belongs_to    :voice_log

  after_create  :increase_counter
  after_update  :decrease_counter
  
  scope :not_deleted, -> {
    where.not({flag: STATE_DELETE})
  }
  
  def do_delete
    
    self.flag = DB_DELETED_FLAG
    
  end
  
  private
  
  def increase_counter
    
    update_counter(1)
  
  end
  
  def decrease_counter
    
    update_counter(-1)
  
  end
  
  def update_counter(v)
  
    code = VoiceLogCounter::CT_COMMENT
    ds   = {
      voice_log_id: self.voice_log_id,
      counter_type: code
    }
    
    vlc = VoiceLogCounter.where(ds).first
    if vlc.nil?
      vlc = VoiceLogCounter.new(ds)
    end
    vlc.valu = vlc.valu + v
    vlc.save
  
  end

end
