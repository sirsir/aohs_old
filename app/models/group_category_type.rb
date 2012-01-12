# == Schema Information
# Schema version: 20100402074157
#
# Table name: group_category_types
#
#  id         :integer(11)     not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  order_id   :integer(10)
#

class GroupCategoryType < ActiveRecord::Base
   has_many :categories, :class_name => "GroupCategory"

   validates_uniqueness_of   :name, :case_sensitive => false
   validates_length_of :name, :minimum => 2

#   after_destroy :delete_relate_data
#
#   def delete_relate_data
#
#   end
 
end
