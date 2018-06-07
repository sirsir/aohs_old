require 'rubygems'
require 'thor/rails'
require 'json'

module Appl
  ENV['RAILS_ENV'] ||= 'production'
  
  class AeonTask < Thor
    include Thor::Rails
    
    desc "sync_users", "sync users data from auto call"
    def sync_users
      opts = AppUtils::ThorOptionParser.parse(options)
      DataSyncer::Aeon::AtlUserSyncer.sync(opts.options)
    end
    
  end
end