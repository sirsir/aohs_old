require 'rubygems'
require 'thor/rails'
require 'json'
require './lib/test/make_sample'
require './lib/test/make_voice_logs'
require './lib/test/make_result_keywords'
require './lib/test/make_computer_log'
require './lib/test/make_app_log'

class SampleData < Thor
  include Thor::Rails
  
  namespace :sample

  desc 'create_group', 'generate sample groups'
  def create_group
    n = 10
    MakeSample.make_groups(n)
  end

  desc 'create_user', 'generate sample user'
  def create_user
    n = 10 * 10
    MakeSample.make_users(n)
  end

  desc 'create_extensions', 'generate extensions'
  def create_extensions
    MakeSample.make_phone_extensions
  end
  
  desc 'create_voice_logs', 'generate voice logs'
  method_option :d,  :type => :string,  :required => false
  def create_voice_logs
    d = options[:d].to_s
    MakeSample.make_voice_logs(d)
  end
  
  desc 'create_apps_log', 'generate app logs'
  method_option :d,  :type => :string,  :required => false
  def create_apps_log
    d = options[:d].to_s
    MakeSample.make_app_logs(d)
  end
  
  desc 'create_computer_logs', 'generate computer logs'
  def create_computer_logs
    MakeComputerLog.make_logs
  end
  
  desc 'test', 'test'
  def test
    AppUtils.exec_call_category
  end
  
end