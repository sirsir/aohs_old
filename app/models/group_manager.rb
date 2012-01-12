# == Schema Information
# Schema version: 20100402074157
#
# Table name: group_managers
#
#  id         :integer(11)     not null, primary key
#  user_id    :integer(10)
#  manager_id :integer(10)
#

class GroupManager < ActiveRecord::Base
  belongs_to :manager, :class_name => "Manager", :foreign_key => "manager_id"
end
