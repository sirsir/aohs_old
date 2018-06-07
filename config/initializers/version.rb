#
# application version control
#

begin
  
  APP_MAJOR_REVISION = 4
  APP_MINOR_REVISION = 0
  APP_MAINTENANCE_REVISION = 32
  APP_BUILD_REVISION = 0
  APP_REVISION_UPDATED_AT = 20180516
  
  APP_REVISION = [APP_MAJOR_REVISION, APP_MINOR_REVISION, APP_MAINTENANCE_REVISION, APP_BUILD_REVISION].join(".")
  Rails.application.config.app_version = APP_REVISION
  
rescue => e
  STDERR.puts e.message
end
