# == Schema Information
# Schema version: 20100402074157
#
# Table name: keyword_groups
#
#  id         :integer(11)     not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

# To change this template, choose Tools | Templates
# and open the template in the editor.

class KeywordGroup < ActiveRecord::Base

  validates_presence_of     :name
  validates_length_of       :name, :minimum => 3
  validates_uniqueness_of   :name, :case_sensitive => false
  
  has_many  :keywords, :through => :keyword_group_maps
  has_many  :keyword_group_maps
  
end
