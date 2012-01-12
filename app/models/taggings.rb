# == Schema Information
# Schema version: 20100402074157
#
# Table name: taggings
#
#  id            :integer(11)     not null, primary key
#  tag_id        :integer(10)
#  taggable_id   :integer(20)     not null
#  tagger_id     :integer(10)
#  tagger_type   :string(255)
#  taggable_type :string(255)
#  context       :string(255)
#  created_at    :datetime
#

class Taggings < ActiveRecord::Base

  has_one :tag, :class_name => "Tag", :foreign_key => "tag_id"
  
end
