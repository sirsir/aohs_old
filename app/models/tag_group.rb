# == Schema Information
# Schema version: 20100402074157
#
# Table name: tag_groups
#
#  id          :integer(11)     not null, primary key
#  name        :string(255)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class TagGroup < ActiveRecord::Base

  has_many   :tags, :class_name => 'Tags'

  validates_length_of      :name, :minimum => 4
  validates_uniqueness_of  :name, :case_sensitive => false

end
