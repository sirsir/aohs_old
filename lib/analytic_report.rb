ANA_REPORT_ROOT = File.join(Rails.root,'lib','reports','analytics')
require File.join(File.dirname(__FILE__),'reports','analytics_report_base')
Dir.glob(File.join(ANA_REPORT_ROOT,"*.rb")).each do |rb|
  require rb
end

module AnalyticReport
end