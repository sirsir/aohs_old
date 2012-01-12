
namespace :application do

   task :statistics => :setup do
      Rake::Task["application:statistics:reset_statistics_type"].invoke
      Rake::Task["application:statistics:delete"].invoke
      Rake::Task["application:statistics:create"].invoke
   end

   namespace :statistics do

      desc 'create'
      task :create => :setup do
        run_statistics
      end
      
      desc 'repair'
      task :repair => :setup do
        repair
      end
      
      desc 'repair'
      task :test => :setup do
        test
      end  
      
      desc 'delete'
      task :delete => :setup do
        [DailyStatistics,WeeklyStatistics,MonthlyStatistics].each do |model_name|
          STDERR.puts "-> Clear #{model_name}"
          model_name.delete_all
        end
      end

      desc 'type'
      task :reset_statistics_type => :setup do
        remove_statistics_type
        create_statistics_type
      end
      
      desc 'type'
      task :create_statistics_type => :setup do
        create_statistics_type
      end

      desc 'type'
      task :remove_statistics_type => :setup do
        remove_statistics_type
      end

   end
end

require 'lib/ami_statistics_report'
include AmiStatisticsReport

def create_statistics_type

    STDERR.puts "--> Creating statisitcs type ... "
    
    statisitcs_types = [
      {:target_model => 'VoiceLog',   :value_type => 'count', :by_agent => true},
      {:target_model => 'VoiceLog',   :value_type => 'count', :by_agent => false},
      {:target_model => 'ResultKeyword',  :value_type => 'sum', :by_agent => false},
      {:target_model => 'ResultKeyword',  :value_type => 'sum:n', :by_agent => true},
      {:target_model => 'ResultKeyword',  :value_type => 'sum:m', :by_agent => true},
      {:target_model => 'ResultKeyword',  :value_type => 'sum:a', :by_agent => true}
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

def run_statistics
    STDERR.puts "--> Running statisitcs ... "
    statistics_main
end

def repair
  statistics_clear
  statistics_main
end

def test
  statistics_clear
  statistics_main
end