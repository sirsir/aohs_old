SYNCER_LIB_HOME = File.join(Rails.root, "lib", "syncers")

require "#{SYNCER_LIB_HOME}/voice_log_syncer"
require "#{SYNCER_LIB_HOME}/atl_user_syncer"

module DataSyncer
  #
  # contain all modules and classes about data syncer.
  #
end
