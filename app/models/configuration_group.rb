class ConfigurationGroup < ActiveRecord::Base
  
  has_paper_trail
  
  has_many    :configurations
  
  def session_name
    
    # rename session name for configuration
    case self.name
    when 'amiwatcher'
      return 'watcher'
    else
      return self.name
    end
    
  end
  
end
