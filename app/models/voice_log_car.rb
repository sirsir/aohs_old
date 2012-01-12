class VoiceLogCar < ActiveRecord::Base
  
  belongs_to :voice_log
  belongs_to :car_number
  
end
