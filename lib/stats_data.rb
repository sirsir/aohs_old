# all feature about statistics data and logs
STATS_LIB_HOME = File.join(Rails.root,'lib','stats')
[
  "stats_base",
  "calendar_maker",
  "mysql_table_info",
  "repeat_call_counter",
  "call_agent_stats",
  "call_evaluation_stats",
  "keyword_counter"
].each do |f|
 require File.join(STATS_LIB_HOME, f)  
end
