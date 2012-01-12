# == Schema Information
# Schema version: 20100402074157
#
# Table name: group_categories
#
#  id                     :integer(11)     not null, primary key
#  group_category_type_id :integer(10)     default(0), not null
#  value                  :string(255)
#  description            :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#

class GroupCategory < ActiveRecord::Base

   has_many     :group_categorizations
   has_many     :groups, :through => :group_categorizations
   belongs_to   :category_type, :class_name => "GroupCategoryType", :foreign_key => "group_category_type_id"

   validates_length_of      :value, :minimum => 2
   validates_uniqueness_of  :value, :case_sensitive => false

end
