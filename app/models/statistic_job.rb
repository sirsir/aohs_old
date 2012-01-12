# == Schema Information
# Schema version: 20100402074157
#
# Table name: statistic_jobs
#
#  id         :integer(11)     not null, primary key
#  start_date :date
#  keyword_id :integer(10)
#  act        :string(255)
#

class StatisticJob < ActiveRecord::Base
end
