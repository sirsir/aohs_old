# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
#

# setting

env :PATH, ENV['PATH']
set :environment, "production"
set :output, { :error => "log/cron_error_log.log", :standard => "log/cron_log.log" }

job_type :thor, 'cd :path && /usr/local/bin/thor :task'

# hourly
# 00 10 20 30 40 50
# 00 15 30 45
# 00 30 40
# 00 30
# 10 25 40 55
# 10 30 50
# 10 40

every '0,15,30,45 8-22 * * *' do
  thor "appl:stats:update_call_statistics"
end

every '10,25,40,55 8-22 * * *' do
  thor "appl:stats:update_phone_counter"
end

every '05 8-22 * * *' do
  thor "appl:stats:update_evaluation_stats"
end

every '10 07-22 * * *' do
  thor "appl:maintenance:cleanup_tmpdir"  
end

every '50 8-22 * * *' do
  thor "appl:stats:update_keyword_counter"
end

every '05 8-19 * * *' do
  thor "appl:maintenance:update_current_computer"
end

every '10 6,12,18,20,22 * * *' do
  thor 'appl:maintenance:export_voicelog'
end

# daily (day and night batch) - run once a day
# 00 00
# 15 00
# 00 04
# 00 05
# 00 06

every '15 0 * * *' do
  thor "appl:stats:update_calendar"
  thor "appl:maintenance:sync_voice_logs -d yesterday"
  thor "appl:maintenance:logrotate"
end

every '20 3 * * *' do
  thor "appl:stats:update_call_statistics --date=yesterday --ndays=-3"
  thor "appl:stats:update_phone_counter --date=yesterday --ndays=-3"
end

every '15 4 * * *' do
  thor "appl:maintenance:housekeep_voice_logs"
  thor "appl:maintenance:housekeep_statistic"
  thor "appl:maintenance:housekeep_es_voice_logs"
end

every '30 4 * * *' do
  thor "appl:maintenance:cleanup_table"
  thor "appl:stats:update_table_info"   
end

every '05 6 * * *' do
  thor "appl:maintenance:init_current_extension" 
end

# others

every '*/1 7-23 * * *' do
  thor "appl:maintenance:sync_hangup_call"
end
