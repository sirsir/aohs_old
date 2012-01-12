# == Schema Information
# Schema version: 20100402074157
#
# Table name: configuration_groups
#
#  id                 :integer(11)     not null, primary key
#  name               :string(100)
#  configuration_type :string(1)
#

class ConfigurationGroup < ActiveRecord::Base
end
