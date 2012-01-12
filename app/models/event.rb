# == Schema Information
# Schema version: 20100402074157
#
# Table name: events
#
#  id            :integer(11)     not null, primary key
#  name          :string(255)
#  target        :string(255)
#  status        :string(255)
#  start_time    :datetime
#  complete_time :datetime
#  sevelity      :integer(10)
#

class Event < ActiveRecord::Base
end
