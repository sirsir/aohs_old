UTILS_LIB_HOME = File.join(Rails.root,'lib','utils')

require "#{UTILS_LIB_HOME}/opt_parser"
require "#{UTILS_LIB_HOME}/data_source"
require "#{UTILS_LIB_HOME}/initial_db"
require "#{UTILS_LIB_HOME}/log_rotations"
require "#{UTILS_LIB_HOME}/color_tool"
require "#{UTILS_LIB_HOME}/tool_info"
require "#{UTILS_LIB_HOME}/text_preprocessor"
require "#{UTILS_LIB_HOME}/text_masking"
require "#{UTILS_LIB_HOME}/install_service"
require "#{UTILS_LIB_HOME}/speech_task_creator"
require "#{UTILS_LIB_HOME}/source_file_checker"
require "#{UTILS_LIB_HOME}/user_passwd"
require "#{UTILS_LIB_HOME}/delete_es_document"

module AppUtils
end
