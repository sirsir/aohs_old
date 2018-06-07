class CallEmotion < ActiveRecord::Base
  
  def self.emotion_icons
    return EmotionInfo.all
  end
  
end
