class CallTrackingLog < ActiveRecord::Base

  belongs_to  :user
  
  scope   :past_days, ->(n){
    where(["DATE(created_at) >= ?",n.days.ago.to_date])
  }

end
