require 'base64'

class UserPicture < ActiveRecord::Base
  
  belongs_to    :user
  
  def store_file(f_uploader)
    
    @fpath = f_uploader.current_path
  
    self.content_type = f_uploader.content_type
    self.file_size    = f_uploader.size
    
    store_data_to_db
    
  end
  
  def image_data_bin
    
    return self.pic_data
  
  end
  
  def image_data_64
    
    return "data:#{self.content_type};base64,#{encode_base64_image}"
    
  end
  
  private
  
  def store_data_to_db
    
    if File.exists?(@fpath)
      self.pic_data = File.read(@fpath)
    else
      self.pic_data = nil
    end
    
  end
  
  def encode_base64_image
    
    return Base64.encode64(self.pic_data)
    
  end
  
end
