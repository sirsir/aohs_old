# == Schema Information
# Schema version: 20100402074157
#
# Table name: voice_log_customers
#
#  id           :integer(20)     not null, primary key
#  voice_log_id :integer(20)     not null
#  customer_id  :integer(10)
#

class VoiceLogCustomer < ActiveRecord::Base 

  belongs_to :voice_log
  belongs_to :customer
  
end
