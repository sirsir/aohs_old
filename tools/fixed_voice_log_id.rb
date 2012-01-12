require 'yaml'
require 'rubygems'  
require 'active_record'  
require 'logger'
require 'net/http'
require 'uri'
require 'fileutils'

DIR_HOME = File.dirname(__FILE__)

class VoiceLogMerge < ActiveRecord::Base 
	set_table_name 'voice_logs_test'	
end
class VoiceLogCounter < ActiveRecord::Base 
end
class VoiceLogToday < ActiveRecord::Base 
	set_table_name 'voice_logs_today_1'	
end
class ResultKeyword < ActiveRecord::Base 
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

def get_max_id_1
	inc = ActiveRecord::Base.connection.select("SHOW TABLE STATUS LIKE 'voice_logs_today_1'")
	return inc.first["Auto_increment"].to_i
end

def get_max_id_2
	inc = ActiveRecord::Base.connection.select("SELECT get_unused_id() AS un_id")
	return inc.first["un_id"].to_i
end

def init_max_id(new_max_id)
	current_max_id = get_max_id_1
	next_max_id = new_max_id + 1
	if next_max_id > current_max_id
		# set next id (auto increment)
		sql = "ALTER TABLE #{VoiceLogToday.table_name} AUTO_INCREMENT = #{next_max_id};"
		ActiveRecord::Base.connection.execute(sql)
		puts sql
		STDERR.puts "UPDATE AUT_INC_ID #{current_max_id} => #{next_max_id}, #{sql}"
	end
end

def add_voice_logs_counter(voice_log_id)
	vc = VoiceLogCounter.find(:first,:conditions => {:voice_log_id => voice_log_id})
	if vc.nil?
		vc = VoiceLogCounter.new({:voice_log_id => voice_log_id})
		vc.save!
	end
end

def recheck_result_keywords(old_voice_log_id,start_time,new_voice_log_id)
	rks = ResultKeyword.find(:all,:select => "id",:conditions => ["voice_log_id = ? AND date(created_at) = ?",old_voice_log_id,Time.parse(start_time).to_date])
	unless rks.empty?
		update_sql = "UPDATE #{ResultKeyword.table_name} SET voice_log_id = #{new_voice_log_id} WHERE voice_log_id IN (#{(rks.map { |x| x.id }).join(',')}) LIMIT #{rks.length}"
		puts update_sql
		ActiveRecord::Base.connection.update(update_sql)
	end
end

def start
		
	# select ids of duplicated records 
	data = ActiveRecord::Base.connection.select("SELECT id,count(id) as id_count FROM #{VoiceLogMerge.table_name} GROUP BY id HAVING count(id) >= 2")
	unless data.empty?
		data.each do |v|

			# select list duplicated records by id (dups - 1 records) 
			dups_count = v["id_count"].to_i
			dups = ActiveRecord::Base.connection.select("SELECT id,call_id,start_time,system_id,device_id,channel_id FROM #{VoiceLogMerge.table_name} WHERE id = #{v["id"]} ORDER BY start_time ASC LIMIT #{dups_count - 1}")
			
			dups.each do |d|
				
				puts "# #{v["id"]}, #{d["call_id"]}"
				
				# get unused id from voice_logs_all or max if not found
				xnew_id = get_max_id_2
				
				# update duplicated id to new id
				update_sql = "UPDATE #{VoiceLogMerge.table_name} SET id = #{xnew_id} WHERE id = #{d['id']} AND call_id = '#{d["call_id"]}' AND start_time = '#{d["start_time"]}' AND system_id = #{d["system_id"]} AND device_id = #{d["device_id"]} AND channel_id = #{d["channel_id"]} LIMIT 1"
				ActiveRecord::Base.connection.update(update_sql)
				puts update_sql
				
				# set max auto increment id of voice_logs_today_2 if change
				init_max_id(xnew_id)
				
				# check voice_logs_counter for current id exist or not
				add_voice_logs_counter(xnew_id)
				
				# recheck result keywords for current id
				recheck_result_keywords(v["id"],d["start_time"],xnew_id)

			end
		end
	end

	#f.close
	
end

if connection_db  
  start
end

