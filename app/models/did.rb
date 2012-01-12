# == Schema Information
# Schema version: 20100402074157
#
# Table name: dids
#
#  id           :integer(11)     not null, primary key
#  number       :string(20)
#  extension_id :integer(10)
#  created_at   :datetime
#  updated_at   :datetime
#

class Did < ActiveRecord::Base
   belongs_to :extension, :foreign_key => "extension_id"
   validates_presence_of :number
   validates_numericality_of :number, :on => :create
   validates_numericality_of :number, :on => :update
end
