class Customer < ActiveRecord::Base
  
  has_many    :call_customers
  has_many    :voice_logs,      through: :call_customers
  
end
