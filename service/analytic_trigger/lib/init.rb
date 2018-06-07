#
# To initial/load dependencies
#

require 'rubygems'
require 'logger'
require 'thread'
gem 'config'
require 'config'
require 'active_record'
require 'restclient'
require 'json'
require 'uri'

require File.join(APP_ROOT,'lib','version')
require File.join(APP_ROOT,'lib','resource')
require File.join(APP_ROOT,'lib','logger')
require File.join(APP_ROOT,'lib','sql_client')
require File.join(APP_ROOT,'lib','els_client')

require File.join(APP_ROOT,'lib','models','voice_log')
require File.join(APP_ROOT,'lib','models','evaluation_question')
require File.join(APP_ROOT,'lib','models','evaluation_answer')
require File.join(APP_ROOT,'lib','models','auto_assessment_log')
require File.join(APP_ROOT,'lib','models','evaluation_plan')
require File.join(APP_ROOT,'lib','models','auto_assessment_setting')
require File.join(APP_ROOT,'lib','models','call_classification')
require File.join(APP_ROOT,'lib','models','call_category')
require File.join(APP_ROOT,'lib','models','keyword')
require File.join(APP_ROOT,'lib','models','keyword_type')
require File.join(APP_ROOT,'lib','models','tag')
require File.join(APP_ROOT,'lib','models','tagging')

require File.join(APP_ROOT,'lib','notification_receiver')
require File.join(APP_ROOT,'lib','ana_task')
require File.join(APP_ROOT,'lib','ana_task_result')
require File.join(APP_ROOT,'lib','ana_task_base')
require File.join(APP_ROOT,'lib','call_classify')
require File.join(APP_ROOT,'lib','call_journey')
require File.join(APP_ROOT,'lib','auto_assessment')
require File.join(APP_ROOT,'lib','auto_summarization')
require File.join(APP_ROOT,'lib','auto_tagging_call')
require File.join(APP_ROOT,'lib','server')
