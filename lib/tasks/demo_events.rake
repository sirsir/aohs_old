
NUMBER_OF_EVENTS = 500

namespace :demo do

   desc 'Create event test data'
   task :events => :setup do
      Rake::Task['demo:events:delete'].invoke
      Rake::Task['demo:events:create'].invoke
   end

   namespace :events do
      desc 'Delete all events'
      task :delete => :setup do
        remove_events
      end

      desc 'Create all events'
      task :create => :setup  do
         create_events
      end
   end
end

def create_events

  STDERR.puts "--> Creating events ..."

  verbs = ["is started", "is stopped"]

  targets = ["AMIMQ_BK","AMIMQ_KK","ASR_01","ASR_02","ASR_03","ASR_04"]

  NUMBER_OF_EVENTS.times do |i|
     verb = verbs[rand(verbs.size)]
     target = targets[rand(targets.size)]
     Event.new(:name => "Queue server #{verb}",
               :sevelity => 1,
               :status => "Success",
               :start_time => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
               :complete_time => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
               :target => target).save
  end

end

def remove_events
  
  STDERR.puts "--> Removing events ..."
  Event.delete_all

end