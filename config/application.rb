require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Aohs
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    # load all file in lib path 
    config.autoload_paths += %W(#{config.root}/lib)
    
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    
    config.time_zone = "Bangkok"
    config.active_record.default_timezone = :local
    
    # hide warning Active Record suppresses errors raised within `after_rollback`/`after_commit`
    config.active_record.raise_in_transactional_callbacks = true
    
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    config.middleware.insert 0, Rack::UTF8Sanitizer
    
    # active jobs
    # config.active_job.queue_adapter = :sidekiq
  end
end
