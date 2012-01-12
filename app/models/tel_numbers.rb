class TelNumbers < ActiveRecord::Base
  belongs_to :customer,:class_name => 'Customers',:foreign_key => 'customer_id'
  belongs_to :voice_log,:class_name => 'VoiceLog',:foreign_key => 'voice_log_id'
end
