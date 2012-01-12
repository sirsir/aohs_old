# == Schema Information
# Schema version: 20100402074157
#
# Table name: groups
#
#  id           :integer(11)     not null, primary key
#  name         :string(255)
#  description  :string(255)
#  leader_id    :integer(10)     default(0), not null
#  lock_version :integer(10)
#  created_at   :datetime
#  updated_at   :datetime
#

class Group < ActiveRecord::Base

   has_many :users
   
   belongs_to :leader, :class_name => "User", :foreign_key => "leader_id" 
   
   belongs_to :configurationData
   has_many :configurations, :through => "ConigurationData"

   has_many :group_categorizations
   has_many :categories, :through => :group_categorizations, :class_name => "GroupCategory"

   validates_presence_of     :name
   validates_uniqueness_of   :name, :case_sensitive => false
   validates_length_of       :name, :minimum => 3
  
   def agent_count
   
     return Agent.count(:id,:conditions => {:group_id => self.id }).to_i
         
   end
   
end
