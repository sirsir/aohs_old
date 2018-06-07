# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# Added Date/Time Format
Date::DATE_FORMATS[:web] = "%Y-%m-%d"
Time::DATE_FORMATS[:web] = "%Y-%m-%d %H:%M:%S"
Time::DATE_FORMATS[:time] = "%H:%M:%S" 