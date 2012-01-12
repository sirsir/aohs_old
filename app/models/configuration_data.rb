# == Schema Information
# Schema version: 20100402074157
#
# Table name: configuration_datas
#
#  id               :integer(11)     not null, primary key
#  configuration_id :integer(10)
#  config_type      :integer(10)
#  config_type_id   :integer(10)
#  value            :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class ConfigurationData < ActiveRecord::Base

  belongs_to :owner, :polymorphic => true

   def convert_type

   end
  
end
