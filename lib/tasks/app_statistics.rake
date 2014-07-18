require 'lib/ami_statistics_report'
include AmiStatisticsReport

namespace :application do

   task :statistics => :setup do
      Rake::Task["application:statistics:types"].invoke
      Rake::Task["application:statistics:delete"].invoke
      Rake::Task["application:statistics:create"].invoke
   end

   namespace :statistics do

      desc 'types'
      task :types => :setup do
        create_statistics_type
      end
      
      desc 'create'
      task :create => :setup do
        statistics_main
      end
      
      desc 'repair_today'
      task :repair_today => :setup do
        #statistics_main
        initial_statistics_setting
        repair_statistics_agents
        repair_statistics_keywords
      end

      desc 'repair_all'
      task :repair_all => :setup do
        statistics_main_repair
      end

      desc 'reset-daily'
      task :reset_daily => :setup do
        clean_statistics_data
		statistics_all_repair
      end
      
      desc 'reset'
      task :reset => :setup do
        clean_statistics_data
        statistics_main_repair
      end
      
      desc 'delete'
      task :delete => :setup do
        clean_statistics_data
      end

   end
end

def create_statistics_type

    STDERR.puts "--> Creating statisitcs type ... "
    
    statisitcs_types = [
      {:target_model => 'VoiceLog',       :value_type => 'count',   :by_agent => true},
      {:target_model => 'VoiceLog',       :value_type => 'count',   :by_agent => false},
      {:target_model => 'VoiceLog',       :value_type => 'count:i', :by_agent => true},
      {:target_model => 'VoiceLog',       :value_type => 'count:o', :by_agent => true},
      {:target_model => 'VoiceLog',       :value_type => 'count:e', :by_agent => true},
      {:target_model => 'ResultKeyword',  :value_type => 'sum',     :by_agent => false},
      {:target_model => 'ResultKeyword',  :value_type => 'sum:n',   :by_agent => true},
      {:target_model => 'ResultKeyword',  :value_type => 'sum:m',   :by_agent => true},
      {:target_model => 'ResultKeyword',  :value_type => 'sum:a',   :by_agent => true}
    ]

    ActiveRecord::Base.transaction do

      statisitcs_types.each do |item|
        if not StatisticsType.exists?(item)
          StatisticsType.new(item).save!
        end
      end
      
    end
    
end

def remove_statistics_type
    STDERR.puts "--> Removing statisitcs type ... "
    StatisticsType.delete_all()
end

def clean_statistics_data
    [DailyStatistics,WeeklyStatistics,MonthlyStatistics].each do |model_name|
      STDERR.puts "-> Clear #{model_name}"
      model_name.delete_all
    end  
end