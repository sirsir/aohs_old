# == Schema Information
# Schema version: 20100402074157
#
# Table name: privileges
#
#  id            :integer(11)     not null, primary key
#  name          :string(255)
#  description   :string(255)
#  lock_version  :integer(10)
#  created_at    :datetime
#  updated_at    :datetime
#  display_group :string(255)
#  order_no      :integer(10)
#

class Privilege < ActiveRecord::Base
   has_many :permissions
   has_many :roles, :through => :permissions

   validates_uniqueness_of   :name, :case_sensitive => false
end
