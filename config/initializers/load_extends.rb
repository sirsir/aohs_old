# used for load extended library for application
#

EXTENDED_PATH = File.join(Rails.root,'lib','extends')

# require "#{EXTENDED_PATH}/array_extended"
require "#{EXTENDED_PATH}/hash_extended"
require "#{EXTENDED_PATH}/string_extended"

require "#{EXTENDED_PATH}/params_helper"
require "#{EXTENDED_PATH}/paginates_helper"
require "#{EXTENDED_PATH}/flash_message_helper"
require "#{EXTENDED_PATH}/handlebars_helper"

ActiveSupport.on_load :action_controller do
  include ParamsHelper::Controller
  include PaginatesHelper::PageHelper
  include FlashMessageHelper::Controller
end

ActiveSupport.on_load :action_view do
  include ParamsHelper::Helper
  include PaginatesHelper::PageHelper
  include HandlebarsHelper::Helper
end