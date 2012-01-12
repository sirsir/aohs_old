require 'yaml'
require 'rubygems'  
require 'active_record'  
require 'logger'
require 'net/http'
require 'uri'
require 'fileutils'

DIR_HOME = File.dirname(__FILE__)

class VoiceLog < ActiveRecord::Base 
	set_table_name 'voice_logs_1'	
end

def connection_db
	
	db_yml = File.join(DIR_HOME, 'database.yml')
	dbconfig = YAML::load(File.open(db_yml))
	begin
		ActiveRecord::Base.configurations = dbconfig
		ActiveRecord::Base.establish_connection(:aohs)		# default database connection
		return true
	rescue => e
		$LOG.error e.message
		return false
	end
	
end

def start

	sdate = Date.parse('2011-01-01')
	edate = Date.parse('2011-05-01')
	
	STDOUT.puts ["Date","Total","Found","Not Found"].join("\t")
	
	(sdate..edate).each do |d|
		
		fname = "#{d.strftime("%Y%m%d")}.error"
		f = File.new(fname,"w")
		
		vls = VoiceLog.find(:all,:select => "id,start_time,call_id,voice_file_url",:conditions => "start_time between '#{d} 00:00:00' and '#{d} 23:59:59'",:order => 'start_time')
		
		found = 0
		vls.each do |v|
			u = URI.parse(v.voice_file_url)
			begin
				http = Net::HTTP.new(u.host,u.port)
				if http.head(v.voice_file_url).code == "200"
					found = found + 1;
				else
					f.puts [v.start_time.strftime("%Y-%m-%d %H:%M:%S"),v.id,v.call_id,v.voice_file_url].join("\t") + "\r\n"
				end
			rescue => e
				## error
				##STDERR.puts e.message
				f.puts [v.start_time.strftime("%Y-%m-%d %H:%M:%S"),v.id,v.call_id,v.voice_file_url].join("\t") + "\r\n"
			end
		end
		
		f.close
		
		if found == vls.length
			FileUtils.rm(fname)
		end
		
		STDOUT.puts [d,vls.length,found,vls.length-found].join("\t")
	end
	
end

if connection_db  
  start
end
