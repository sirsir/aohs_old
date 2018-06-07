class CallCustomer < ActiveRecord::Base
  
  belongs_to  :voice_log
  belongs_to  :customer
  
end
