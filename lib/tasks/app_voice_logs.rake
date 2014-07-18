namespace :application do

  desc 'VoiceLogs'
  task :voice_logs => :setup do
    
  end

  namespace :voice_logs do

     desc 'voice_log_counter'
     task :voice_log_counter => :voice_logs do
        repair_voice_logs_counter
     end

     desc 'voice_log_counter2[YYYYMMDD]'
     task :voice_log_counter2, [:period] => :voice_logs do |t, args|
		args.with_defaults(:period => nil)
        AmiVoiceLog.repair_voice_log_counters_on(args.period)
     end
	 
  end

end

def repair_voice_logs_counter

  STDOUT.puts "Repairing voice_log_counters"
  
  AmiVoiceLog.repair_voice_log_counters_all
    
  STDOUT.puts "Finished"
  
end