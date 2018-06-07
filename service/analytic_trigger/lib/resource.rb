module AnalyticTrigger
  class Resource
    
    def self.web_configuration_files
      files = {
        default: File.join(RAILS_APP_ROOT, 'config', 'settings.yml'),
        local: File.join(RAILS_APP_ROOT, 'config', 'settings.local.yml')
      }
      return files
    end
    
  end
end