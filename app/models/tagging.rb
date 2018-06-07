class Tagging < ActiveRecord::Base
  
  has_many      :voice_logs, foreign_key: :tagged_id
  belongs_to    :tag
  
  after_create  :increase_counter
  after_destroy :decrease_counter
  
  scope :find_by_voice_log, ->(v){
    where(tagged_id: v)
  }
  
  private
  
  def increase_counter
    update_counter(1)
  end
  
  def decrease_counter
    update_counter(-1)
  end
  
  def update_counter(v)
    code = VoiceLogCounter::CT_TAGGING
    da = {
      voice_log_id: self.tagged_id,
      counter_type: code
    }
    vlc = VoiceLogCounter.where(da).first
    if vlc.nil?
      vlc = VoiceLogCounter.new(da)
    end
    vlc.valu = vlc.valu + v
    vlc.save
  end
  
  # end class
end
