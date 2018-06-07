class CallFavourite < ActiveRecord::Base
  
  belongs_to    :voice_log
  belongs_to    :user
  
end
