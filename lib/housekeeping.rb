HOUSEKEEP_LIB_HOME = File.join(Rails.root,'lib','housekeeping')
require "#{HOUSEKEEP_LIB_HOME}/housekeeping_base"
require "#{HOUSEKEEP_LIB_HOME}/hskp_voice_log"
require "#{HOUSEKEEP_LIB_HOME}/hskp_es_voice_log"
require "#{HOUSEKEEP_LIB_HOME}/hskp_stats"
require "#{HOUSEKEEP_LIB_HOME}/hskp_logs"
require "#{HOUSEKEEP_LIB_HOME}/hskp_temp"
require "#{HOUSEKEEP_LIB_HOME}/hskp_user"

module Housekeeping
  include HousekeepingData
  
  def self.do_all_tasks
    HskpLogs.cleanup_table_logs
    HskpTemp.cleanup_temp_table
    HskpUser.check_users
  end
  
end