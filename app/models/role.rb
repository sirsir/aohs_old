# == Schema Information
# Schema version: 20100402074157
#
# Table name: roles
#
#  id           :integer(11)     not null, primary key
#  name         :string(255)
#  description  :string(255)
#  lock_version :integer(10)
#  created_at   :datetime
#  updated_at   :datetime
#

class Role < ActiveRecord::Base
   has_many :permissions
   has_many :privileges, :through => :permissions

   has_many :users

   validates_uniqueness_of   :name, :case_sensitive => false
   validates_length_of       :name, :within => 2..40
   
end
