# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
AohsWeb::Application.initialize!

begin 
  AmiLog.set_flog
  AmiConfig.configurations_repair
  #AmiTool.update_db_connection_string
  AmiTimeline.set_jnlp_file_and_js
  AmiTool.make_public_file
  AmiTool.switch_table_voice_logs
rescue => e
  STDERR.puts e.message
end

begin
  AmiScheduler.run
rescue => e
  STDERR.puts e.message
end