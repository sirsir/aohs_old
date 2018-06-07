module AnalyticTrigger
  
  def self.logger
    unless defined? $LOGGER
      $LOGGER = Logger.new(File.join('/var','log','aohs','analytic_trigger.log'), 'daily')
    end
    $LOGGER
  end
  
end