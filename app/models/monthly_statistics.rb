# == Schema Information
# Schema version: 20100402074157
#
# Table name: monthly_statistics
#
#  id                 :integer(11)     not null, primary key
#  start_day          :date            not null
#  agent_id           :integer(10)
#  keyword_id         :integer(10)
#  statistics_type_id :integer(10)     not null
#  value              :integer(10)
#  created_at         :datetime
#  updated_at         :datetime
#

class MonthlyStatistics < ActiveRecord::Base

   def label
      start_day.strftime('%Y-%m')
   end
end
