# == Schema Information
# Schema version: 20100402074157
#
# Table name: group_category_display_trees
#
#  id                  :integer(11)     not null, primary key
#  group_category_type :string(255)
#  parent_id           :integer(10)
#  lft                 :integer(10)
#  rgt                 :integer(10)
#  created_at          :datetime
#  updated_at          :datetime
#

class GroupCategoryDisplayTree < ActiveRecord::Base
  
  belongs_to   :group_category_type, :class_name => "GroupCategoryType", :foreign_key => "group_category_type"

end
