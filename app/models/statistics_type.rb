# == Schema Information
# Schema version: 20100402074157
#
# Table name: statistics_types
#
#  id           :integer(11)     not null, primary key
#  target_model :string(255)
#  value_type   :string(255)
#  by_agent     :boolean(1)
#  created_at   :datetime
#  updated_at   :datetime
#

class StatisticsType < ActiveRecord::Base

   # params is expected hash. The hash has following key and values.
   #   :target_model
   #   :by_agent
   #   :value_type
   # for example,
   #  {:target_model=>"ResultKeyword",:by_agent=>false, :value_type=>"sum"}
   
   def self.find_statistics(params)
        StatisticsType.where([":target_model=target_model and :by_agent=by_agent and :value_type=value_type",params]).first
   end
   
   def self.find_statistics_all(params)
        StatisticsType.where([":target_model=target_model and :by_agent=by_agent and value_type in (:value_type) ",params])
   end
   
end
