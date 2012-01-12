# == Schema Information
# Schema version: 20100402074157
#
# Table name: group_categorizations
#
#  id                :integer(11)     not null, primary key
#  group_id          :integer(10)     default(0), not null
#  group_category_id :integer(10)     default(0), not null
#  created_at        :datetime
#  updated_at        :datetime
#

class GroupCategorization < ActiveRecord::Base

   #belongs_to :category, :dependent => :destroy, :class_name => "GroupCategory", :foreign_key => "group_category_id"
   #belongs_to :group, :dependent => :destroy

   belongs_to :category, :class_name => "GroupCategory", :foreign_key => "group_category_id"
   belongs_to :group

end
