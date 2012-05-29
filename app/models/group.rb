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
    
   after_destroy :remove_group
   before_save :default_values
   
   def agent_count
   
     return Agent.alive.where({:group_id => self.id }).count.to_i
         
   end
   
   def remove_group
     
     group_id = self.id
     
     # remove category
     gct = GroupCategorization.select(:id).where(:group_id => group_id)
     gct.each { |x| GroupCategorization.destroy(x.id) }
     
     # remove group member
     group_members = GroupMember.where(:group_id => group_id).all
     unless group_members.empty?
       GroupMember.delete(group_members)
     end
     
   end
 
   private

   def default_values
      self.leader_id ||= 0
   end
   
end
