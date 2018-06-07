class EmotionInfo < ActiveRecord::Base
  
  def css_content_class
    "emotion-#{self.id}"  
  end
  
  def image_path
    File.join("emotions",self.image_name)  
  end
  
end
