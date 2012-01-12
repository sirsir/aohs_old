# == Schema Information
# Schema version: 20100402074157
#
# Table name: customers
#
#  id            :integer(10)     not null, primary key
#  customer_name :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class Customers < ActiveRecord::Base

  has_many :customer_numbers, :class_name => "CustomerNumbers", :foreign_key => 'customer_id'

  has_many :voice_log_customers, :class_name => "VoiceLogCustomer" 
  has_many :voice_logs, :through => :voice_log_customers
  
  validates_length_of       :customer_name,    :within => 4..255
  validates_uniqueness_of   :customer_name, :message => 'duplicate'

end
