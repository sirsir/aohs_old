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
  
   has_many   :dids                     ,:class_name => "Did"
   has_one    :computer_extension_map
      
   validates_presence_of :number
   validates_numericality_of :number, :on => :create
   validates_numericality_of :number, :on => :update
   
   after_destroy :remove_relate_extensions
      
   def cws
     begin
       @@cws = CurrentWatcherStatus.where("(extension = '#{self.number}' or extension2 = '#{self.number}')").order("check_time desc").first
     rescue => e
       @@cws = nil
     end  
   end
      
   def dids_list
      dids = self.dids
      if dids.empty?
        return nil
      else
        return (dids.map { |d| d.number } ).join(',')
      end
   end
    
   def current_remote_computer
      computer_name = nil
      remote_ip = nil      
      login_name = nil
      last_updated = nil
      tcws = self.cws
      
      unless tcws.nil?
        # from extension_agent_map
        remote_ip = tcws.remote_ip
        ccs = CurrentComputerStatus.where(:remote_ip => remote_ip).order("check_time desc").first
        unless ccs.nil?
          computer_name = ccs.computer_name
          login_name = ccs.login_name
          last_updated = ccs.check_time
        end
      else
        # from computer extension map
        cem = ComputerExtensionMap.where(:extension_id => self.id).first
        unless cem.nil?
          computer_name = cem.computer_name
          remote_ip = cem.ip_address
          ccs = CurrentComputerStatus.where(:remote_ip => remote_ip, :computer_name => computer_name).order("check_time desc").first
          unless ccs.nil?
            last_updated = ccs.check_time
          end
        end
      end
      
      @@current_remote_computer = ComputerInfo.new({:computer_name => computer_name, :remote_ip => remote_ip, :login_name => login_name, :check_time => last_updated})
   end
   
   def current_remote_user
      eam = ExtensionToAgentMap.where({:extension => self.number }).first 
      @@remote_user = nil
      unless eam.nil?
        u = User.alive.where(:id => eam.agent_id).first
        unless u.nil?
          @@remote_user = u  
        end
      end
   end
 
   protected
   def remove_relate_extensions
     extension_id = self.id
     extension_number = self.number
     if extension_id > 0
        ComputerExtensionMap.delete_all(:extension_id => extension_id)
        ExtensionToAgentMap.delete_all(:extension => extension_number)
        dids = Did.where(:extension_id => extension_id)
        dids.each do |did|
          DidAgentMap.delete_all(:number => did)
        end
        Did.delete(dids)          
     end
   end

   class ComputerInfo
      def initialize(d={})
          @@computer_name = d[:computer_name]
          @@remote_ip = d[:remote_ip]
          @@login_name = d[:login_name]
          @@check_time = d[:check_time]
      end
      def computer_name
        @@computer_name
      end
      def remote_ip
        @@remote_ip  
      end
      def login_name
        @@login_name  
      end
      def check_time
        @@check_time
      end
   end
  
end
