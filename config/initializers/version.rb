# script to generate version file. ../config/version.rb

def update_application_version
  if Rails.env.development?
    File.open(VERS_FILE,'w') do |file|
      file.write `git describe --tags --always`
    end
  end
end

begin
  VERS_FILE = File.join(Rails.root,'config','version')
  update_application_version
rescue => e
  STDERR.puts e.message
end

if File.exist?(VERS_FILE)
  APP_VERSION = File.read(VERS_FILE)  
end

