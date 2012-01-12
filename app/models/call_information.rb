# == Schema Information
# Schema version: 20100402074157
#
# Table name: call_informations
#
#  id           :integer(20)     not null, primary key
#  voice_log_id :integer(20)     not null
#  start_msec   :integer(10)
#  end_msec     :integer(10)
#  event        :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  agent_id     :integer(10)
#

class CallInformation < ActiveRecord::Base
   belongs_to :voice_log

   def start_sec
      start_msec.to_f / 1000
   end
   def end_sec
      end_msec.to_f / 1000
   end

end
