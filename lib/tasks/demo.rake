namespace :demo do

   desc 'Setup App'
   task :setup => :environment do

   end

   desc "Rebuild demo data"
   task :rebuild => :setup do

      Rake::Task['application:create'].invoke
      Rake::Task["demo:users_and_groups"].invoke
      #Rake::Task["demo:keywords"].invoke
      #Rake::Task["demo:events"].invoke
      #Rake::Task["demo:logs"].invoke
      
   end

   desc "build test data"
   task :build_data => :setup do

      Rake::Task["demo:voice_logs"].invoke
      Rake::Task["demo:statistics"].invoke
     
   end

   desc "Rebuild demo data"
   task :build_voice_logs => :setup do

      Rake::Task["demo:voice_logs"].invoke
      
   end

   desc "Rebuild demo data"
   task :build_statistics => :setup do

      Rake::Task["application:statistics:delete"].invoke
      Rake::Task["application:statistics:create"].invoke

   end

  desc 'map agent to extension and dids'
  task :map_agent_to_did => :setup do
     STDOUT.puts "---- start mapping agent's  extension for dids number. ----"
     emap = ExtensionToAgentMap.find(:all)
     unless emap.empty?
     STDOUT.puts "---- founded agent's extension now mapping in progress..."
     emap.each do |ep|
       ext = Extension.find(:first,:conditions =>{:number => ep.extension})
       unless ext.dids.blank?
             ext.dids.each do |d|
                   unless  DidAgentMap.exists?({:number => d.number,:agent_id => ep.agent_id})
                   dap = DidAgentMap.new(:number => d.number,:agent_id => ep.agent_id)
                   dap.save!
                   end
             end
         end unless ext.blank?
     end
     else
     STDOUT.puts "---- can not found agent's extension task terminated ~!"
     end
  end

  desc 'test'
  task :test => :setup do
    AmiScheduler.create_job
  end

 end