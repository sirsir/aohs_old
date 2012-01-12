# == Schema Information
# Schema version: 20100402074157
#
# Table name: keyword_group_maps
#
#  id               :integer(11)     not null, primary key
#  keyword_id       :integer(10)     not null
#  keyword_group_id :integer(10)     not null
#  created_at       :datetime
#  updated_at       :datetime
#

class KeywordGroupMap < ActiveRecord::Base

  belongs_to :keyword_group
  belongs_to :keyword
  
end
