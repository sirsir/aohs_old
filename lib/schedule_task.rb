require 'rufus-scheduler'

module ScheduleTask
  
  def self.start
    
    STDOUT.puts "Starting schedule tasks"
    
    scheduler = Rufus::Scheduler.new
    
  end
  
end