# == Schema Information
# Schema version: 20100402074157
#
# Table name: tags
#
#  id           :integer(11)     not null, primary key
#  name         :string(255)
#  tag_group_id :integer(10)
#

class Tags < ActiveRecord::Base

  has_many :taggings, :class_name => 'Taggings', :foreign_key => "tag_id"
  belongs_to  :tag_group, :foreign_key => "tag_group_id"

  validates_length_of      :name, :minimum => 4
  validates_uniqueness_of  :name, :case_sensitive => false
 
end
