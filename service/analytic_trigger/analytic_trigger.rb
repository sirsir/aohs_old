APP_ROOT = File.expand_path(File.dirname(__FILE__))
APP_DATA = File.join(APP_ROOT,'lib','data')
RAILS_APP_ROOT = APP_ROOT.gsub('service/analytic_trigger','')
RAILS_APP_LIB = File.join(RAILS_APP_ROOT, 'lib')
require File.join(APP_ROOT,'lib','init')

module AnalyticTrigger
  # application/main module
end
