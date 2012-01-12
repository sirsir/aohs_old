require 'rubygems'
require 'yaml'
#require "#{RAILS_ROOT}/vendor/plugins/sqljdbc/sqljdbc.jar"
require "#{RAILS_ROOT}/vendor/plugins/sqljdbc/sqljdbc4.jar"
 
DB_CONFIG_FILE = "#{RAILS_ROOT}/config/databases.yml"

class Dnis < ActiveRecord::Base
  set_table_name 'dnis'
end
 
class DnisAgentUpdater

  def initialize(connection_string="")
    
    STDOUT.puts "[dnis-agent-updater] - initialize"
    STDOUT.puts "[dnis-agent-updater] - db configuration => #{DB_CONFIG_FILE}"
    
    dbconfig = YAML::load(File.open(DB_CONFIG_FILE))
    
    Dnis.configurations = dbconfig
    Dnis.establish_connection(:genesys_urs) 
    
    @update_option = 1
    
    STDOUT.puts "[dnis-agent-updater] - db_url    => #{dbconfig['genesys_urs']['url']}"
    STDOUT.puts "[dnis-agent-updater] - db_driver => #{dbconfig['genesys_urs']['driver']}"
    STDOUT.puts "[dnis-agent-updater] - db_user   => #{dbconfig['genesys_urs']['username']}"
    
    case @update_option
    when 0
      STDOUT.puts "[dnis-agent-updater] - Update with => replace all"
    when 1
      STDOUT.puts "[dnis-agent-updater] - Update with => update if exist"
    end
    
  end
  
  def update

    result = false
    
    begin
            
       if @update_option == 0
         
         STDOUT.puts "[dnis-agent-updater] - delete all dnis_agents"
         dnis_agent_count = DnisAgent.count(:id)
         DnisAgent.delete_all
         STDOUT.puts "[dnis-agent-updater] - deleted #{dnis_agent_count} records"
         
       end
       
       sql = "SELECT * FROM dnis"
       STDOUT.puts "[dnis-agent-updater] - exec #{sql}"
       dnis_agents = Dnis.find(:all);
      
       STDOUT.puts "[dnis-agent-updater] - Found dnis #{dnis_agents.length}"
       unless dnis_agents.empty?
         
         STDOUT.puts "[dnis-agent-updater] - updating dnis_agent table"
         dnis_agents.each do |r|
           
           dnis = r.dnis
           agent = r.agent
           team = r.team
           
           o = DnisAgent.find(:first,:conditions => {:dnis => dnis, :ctilogin => agent })
           if o.nil?
             d = DnisAgent.create({:dnis => dnis, :ctilogin => ctilogin, :team => team})
             STDOUT.puts "[dnis-agent-updater] - insert     : #{dnis}, #{agent}"
           else
             if @update_option == 1
              STDOUT.puts "[dnis-agent-updater] - update     : #{dnis}, #{agent}"
               d = DnisAgent.update(o.id,{:dnis => dnis, :ctilogin => agent, :team => team})
             else
              STDOUT.puts "[dnis-agent-updater] - duplicate  : #{dnis}, #{agent}"  
             end
           end
           
         end
         
       end
       
      STDOUT.puts "[dnis-agent-updater] - updating dnis_agent was finished."
      
      Dnis.clear_active_connections! 
       
      result = true
          
    rescue => e
      
      STDOUT.puts "[dnis-agent-updater] - #{e.message}"
      
      result = e.message
      
    end
    
    return result
    
  end
    
end