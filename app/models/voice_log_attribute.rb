class VoiceLogAttribute < ActiveRecord::Base
  
  # number of audio channels
  # 1.0 = mono, 2.0 = stereo
  ATTR_AUDIO_CHANNELS   = 10
  # agent speaker channel
  # 0 = L, 1 = R
  ATTR_SPEAKER_AGENT    = 11
  # speech recognition status
  # Y = error/failed
  ATTR_SR_ERR_CH0       = 21
  ATTR_SR_ERR_CH1       = 22
  
  # result of call
  ATTR_CALL_RESULT      = 100
  
  scope :default_select, ->{
    list = [
      ATTR_CALL_RESULT
    ]
    where(attr_type: list)  
  }

end
