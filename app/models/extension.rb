# == Schema Information
# Schema version: 20100402074157
#
# Table name: extensions
#
#  id         :integer(11)     not null, primary key
#  number     :string(20)
#  created_at :datetime
#  updated_at :datetime
#

class Extension < ActiveRecord::Base
  
   has_many :dids ,:class_name => "Did"
      
   validates_presence_of :number
   validates_numericality_of :number, :on => :create
   validates_numericality_of :number, :on => :update
   
   def cws
     
     begin
       return CurrentWatcherStatus.find(:first,:conditions => "extension = '#{self.number}' or extension2 = '#{self.number}'", :order => "check_time desc")
     rescue => e
       STDOUT.puts e.message
       return nil
     end  
     
   end
   
end
