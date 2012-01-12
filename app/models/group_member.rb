# == Schema Information
# Schema version: 20100402074157
#
# Table name: group_members
#
#  id         :integer(11)     not null, primary key
#  group_id   :integer(10)
#  user_id    :integer(10)
#  created_at :datetime
#  updated_at :datetime
#

class GroupMember < ActiveRecord::Base
  belongs_to :users, :class_name => "User", :foreign_key => "user_id"
  belongs_to :group, :class_name => "Group", :foreign_key => "group_id"
end
