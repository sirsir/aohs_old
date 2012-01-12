require 'digest/md5'

namespace :demo do

   desc 'Create user and group test data'
   task :voice_logs => :setup do
      Rake::Task["demo:voice_logs:remove"].invoke
      Rake::Task["demo:voice_logs:create"].invoke
   end

   namespace :voice_logs do

      desc 'Delete all'
      task :remove => :setup do
        remove_voice_logs
      end

      desc 'Create test data'
      task :create => :setup do
        #create_voice_logs(-6)
	#create_voice_logs(-1)
        create_voice_logs(-3)
	create_voice_logs(1)
      end
    
      desc 'Compare'
      task :compare => :setup do
        compare_voice_logs
      end
    
   end

   desc 'test delete'
   task :voice_logs_dels => :setup do
      vs = VoiceLogTemp.find(:all,{:select => :id})
      while not vs.empty?
	 v = vs.pop
	 STDOUT.puts "Deleting #{v.id}"
	 ActiveRecord::Base.connection.execute("call reset_result_keywords_with_voiceid(#{v.id});");
      end
   end
   
end

def remove_voice_logs

   STDERR.puts "--> Removing voice log and reference table"

   targets = [VoiceLog, ResultKeyword, CallInformation, CallBookmark]
   targets.each do |m|
      m.delete_all
      STDERR.puts "#{m} is deleted all"
   end

end

def create_voice_logs(num_of_months)

  $NUMBER_OF_MONTHS = num_of_months							# 0 is TODAY, x < 0 is PAST and TODAY, x > 0 is TOMORROW and FUTURE
  $NUMBER_OF_CALLS_PER_AGENT_PER_DAY = 6
  $NUMBER_OF_AGENT_HOLIDAY = 30
  $MAX_CALL_DURATION = 3000
  $MIN_CALL_DURATION = 1800
  $BETWEEN_CALL_TIME = 120
  $BETWEEN_CALL_TIME_DEFAULT = 5
  $NOF_AGENTS = 1500  
  $VOICES = voices = ['sample001-01.spx',
	'sample001-01.wav',
	'sample001-02.wav',
	'sample001-03.wav',
	'sample002-01.spx',
	'sample002-01.wav',
	'sample002-02.wav',
	'sample002-03.wav',
	'sample003-01.spx',
	'sample003-01.wav',
	'sample003-02.wav',
	'sample004-01.spx',
	'sample004-02.spx'] 
#['001.wav','002.wav','003.wav']

  customer_names = []
  customer_names_file = File.join(File.dirname(__FILE__),"FIRST_NAME.txt")
  File.open(customer_names_file).each do |line|
    customer_names << "#{line.to_s.strip}".downcase
  end

  target_dir = "/tmp"
  voice_log_file1 = "#{target_dir}/voice_logs_1.sql"
  voice_log_file2 = "#{target_dir}/voice_logs_2.sql"
  result_keyword_file = "#{target_dir}/result_keywords.sql"
  call_info_file = "#{target_dir}/call_informations.sql"
  call_bookmark = "#{target_dir}/call_bookmarks.sql"
  voice_log_counters = "#{target_dir}/voice_log_counters.sql"

  if File.exist?(voice_log_file1)
    File.delete(voice_log_file1)
  end
  if File.exist?(voice_log_file2)
    File.delete(voice_log_file2)
  end  
  if File.exist?(result_keyword_file)
    File.delete(result_keyword_file)
  end
  if File.exist?(call_info_file)
    File.delete(call_info_file)
  end
  if File.exist?(call_bookmark)
    File.delete(call_bookmark)
  end
  if File.exist?(voice_log_counters)
    File.delete(voice_log_counters)
  end

  fvc1 = File.new(voice_log_file1, "a")
  fvc2 = File.new(voice_log_file2, "a")
  frk = File.new(result_keyword_file, "a")
  fci = File.new(call_info_file, "a")
  fcb = File.new(call_bookmark, "a")
  fvt = File.new(voice_log_counters, "a")

  STDERR.puts "--> Creating voice logs ..."

    agents = Agent.find(:all,:limit => $NOF_AGENTS)
    managers = Manager.find(:all)
    agents = agents.concat(managers)
  
    keywords = Keyword.find(:all)

    tf_agents_id = agents.map { |ag| ag.id }

    if $NUMBER_OF_MONTHS == 0
        log_start_date = Date.today
        log_end_date = log_start_date
    elsif $NUMBER_OF_MONTHS < 0
		log_start_date = Date.today << $NUMBER_OF_MONTHS.abs
		log_end_date = Date.today
	else
		log_start_date = Date.today + 1
		log_end_date = Date.today + 1 + ($NUMBER_OF_MONTHS * 30)
	end

    tmp_tbl = VoiceLogTemp.find(:first, :select => "max(id) as max_id")
    max_voice_id = tmp_tbl.max_id.to_i
    tmp_tbl = ResultKeyword.find(:first, :select => "max(id) as max_id")
    max_res_keyword_id = tmp_tbl.max_id.to_i
    tmp_tbl = CallInformation.find(:first, :select => "max(id) as max_id")
    max_call_info_id = tmp_tbl.max_id.to_i
    tmp_tbl = CallBookmark.find(:first, :select => "max(id) as max_id")
    max_call_book_id = tmp_tbl.max_id.to_i
    tmp_tbl = VoiceLogCounter.find(:first, :select => "max(id) as max_id")
    max_vc_counter_id = tmp_tbl.max_id.to_i
    
    call_counter = 0
    voice_log_id = max_voice_id + 10
    result_keyword_id = max_res_keyword_id + 10
    call_info_id = max_call_info_id + 10
    call_bookmark_id = max_call_book_id + 10

    vc_cols = []
    rk_cols = []
    ci_cols = []
    cb_cols = []
    vt_cols = []
  
    STDERR.puts "   -> creating voice log from #{log_start_date} to #{log_end_date}"

    periods = (log_start_date..log_end_date).to_a

    periods.each do |start_date|

      STDERR.puts "   -> logs date : #{start_date.strftime('%Y-%m-%d')} : [#{call_counter}]"

      agents.each do |agent|
        if true
          agent_name = agent.display_name
          agent_id = agent.id
          group_name = (agent.group_id.to_i <= 0 ? "" : agent.group.name)
          group_id = (agent.group_id.to_i <= 0 ? 0 : agent.group.id)

          start_time = Time.local(log_start_date.year, log_start_date.month, log_start_date.day, 8, 0, 0) - rand(100)

          number_of_calls_per_day = $NUMBER_OF_CALLS_PER_AGENT_PER_DAY + rand(3) #- rand($NUMBER_OF_CALLS_PER_AGENT_PER_DAY/2) + rand($NUMBER_OF_CALLS_PER_AGENT_PER_DAY/2)

          duration = 0
          1.upto(number_of_calls_per_day) do |i|

            #STDERR.puts "   -> logs date : #{start_date.strftime('%Y-%m-%d')} : [#{call_counter}]" if call_counter%1000 == 0

            start_time += (duration + $BETWEEN_CALL_TIME_DEFAULT + rand($BETWEEN_CALL_TIME))
            if rand(10) == 7
              start_time += 500
            end

            call_counter += 1
            system_id = rand(3)
            device_id = rand(360)
            channel_id = rand(1000)
            
            ani = '08' + sprintf('%08d',rand(100000))
            dnis = '08' + sprintf('%08d',rand(100000))
            extension = '5' + sprintf('%04d',rand(1000))

            if rand(10) == 0 or rand(10) == 1
              duration = rand($MAX_CALL_DURATION) + 30
            else
              duration = rand($MIN_CALL_DURATION) + 30
            end

            hangup_cause = 14
            call_reference = rand(255)
            disposition = "http://192.168.1.17/logger0/voice/data/2011/#{voices[rand(voices.length-1)]}"
            
	    customer = sprintf("#{customer_names[rand(customer_names.length)]}-%03d",rand(999))

            if rand(100) == 3
              call_direction = ["e","u"][rand(2)]
            else
              call_direction = ["i","o"][rand(2)]
            end
      
            updated_at = Time.now
            created_at = updated_at

            voice_log = {
                      :id => voice_log_id,
                      :system_id => system_id,
                      :device_id => device_id,
                      :channel_id => channel_id,
                      :ani => ani,
                      :dnis => dnis,
                      :extension => extension,
                      :start_time => "#{start_date.strftime("%Y-%m-%d")} #{start_time.strftime("%H:%M:%S")}",
                      :duration => duration,
                      :hangup_cause => hangup_cause,
                      :call_reference => call_reference,
                      :agent_id => (rand(1000) == 500 ? "\N" : agent_id),
                      :voice_file_url => disposition,
                      :call_direction => call_direction,
                      :digest => Digest::MD5.hexdigest("#{voice_log_id}-#{call_direction}-#{agent_id}"),
                      :call_id => "#{sprintf('%015d',rand(1000000000000000))}#{sprintf('%010d',voice_log_id)}",
                      :site_id => rand(4)
                      }

            voice_log_counter = {
                      :id => voice_log_id,
                      :voice_log_id => voice_log_id,
                      :keyword_count => 0,
                      :ngword_count => 0,
                      :mustword_count => 0,
                      :bookmark_count => 0
                    }
            
            voice_log_id = voice_log_id + 1

            ranges = []
            stime, etime = 0, 0
            1.upto(rand(10)) do |j|
                stime = etime + rand(5000) + 1
                break if stime > duration * 1000
                etime = stime + rand(5000) + 1
                break if etime > duration * 1000
                ranges << [stime, etime]
            end

            ngword_count, mustword_count, bookmark_count = 0, 0, 0

            ranges.each do |stime, etime|

                case rand(10)
                when 0,1,2,3
                    keyword = keywords[rand(keywords.size-1)]
                    keyword_type = keyword.keyword_type.to_s
                    case keyword_type
                    when /n/
                      ngword_count += 1
                    when /m/
                      mustword_count += 1
		                else
		                     # other
                    end
                    resultkeyword = {
                        :id => result_keyword_id,
                        :start_msec => stime,
                        :end_msec => etime,
                        :voice_log_id => voice_log_id,
                        :keyword_id => keyword.id,
                        :created_at => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
                        :updated_at => Time.now.strftime('%Y-%m-%d %H:%M:%S')
                    }
                    result_keyword_id = result_keyword_id + 1

                    elements = []
                    w = []
                    resultkeyword.each do |key,value|
                      elements << "#{value}"
                      w << key
                    end
                    rk_cols = w
                    sql = elements.join(',')

                    frk.syswrite(sql + "\r\n")

                when 6,7
                    event = "Hold"
                    tf_agent_id = nil
                    if(rand(10) > 7)
                      event = "Transfer"
                      tf_agent_id = tf_agents_id[rand(tf_agents_id.length-1)]
                    end
                    callinformation = {
                        :id => call_info_id,
                        :voice_log_id => voice_log_id,
                        :start_msec => stime,
                        :end_msec => etime,
                        :event => event,
                        :agent_id => tf_agent_id,
                        :created_at => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
                        :updated_at => Time.now.strftime('%Y-%m-%d %H:%M:%S')
                    }
                    call_info_id = call_info_id + 1

                    w = []
                    elements = []
                    callinformation.each do |key,value|
                      elements << "#{value}"
                      w << key
                    end
                    ci_cols = w
                    sql = elements.join(',')

                    fci.syswrite(sql + "\r\n")

                when 8,9
				    bk_list = ["คุยนอกเรื่อง--โทรดูดวงกับหมดดู","คุยนอกเรื่อง--โทรเ่ล่นหุ้น","คุยนอกเรื่อง--ใช้โทรศัพท์คุยหาแฟน","ข่มขู่ลูกค้า--พูดจาข่มขู่ดูถูกลูกค้าเกินไป","ต่อว่าพนักงาน--ต่อว่าพนักงานรับสายพูดจาหยาบคาย","หนักงานให้มูลผิด--ให้ข้อมูลลูกค้าผิด ไม่ตรงกับความเป็นจริง"].rand
                    title = bk_list.split("--")[0]
                    body = bk_list.split("--")[1]
                    bookmark_count += 1
                    callbookmark = {
                        :id => call_bookmark_id ,
                        :voice_log_id => voice_log_id,
                        :start_msec => stime,
                        :end_msec => etime,
                        :title => title,
                        :body => body,
                        :created_at => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
                        :updated_at => Time.now.strftime('%Y-%m-%d %H:%M:%S')
                    }
                    call_bookmark_id = call_bookmark_id + 1

                    w = []
                    elements = []
                    callbookmark.each do |key,value|
                      elements << "#{value}"
                      w << key
                    end
                    cb_cols = w
                    sql = elements.join(',')

                    fcb.syswrite(sql + "\r\n")
                end

            end

            voice_log_counter[:ngword_count] = ngword_count
            voice_log_counter[:mustword_count] = mustword_count
            voice_log_counter[:bookmark_count] = bookmark_count
            voice_log_counter[:keyword_count] = ngword_count + mustword_count

            w = []
            elements = []
            voice_log.each do |key,value|
              elements << "#{value}"
              w << key
            end
            vc_cols = w
            sql = elements.join(',')

			if rand(10) == 5
				fvc1.syswrite(sql + "\r\n")
			else
				fvc1.syswrite(sql + "\r\n")
				fvc2.syswrite(sql + "\r\n")			
			end
            
            w = []
            elements = []
            voice_log_counter.each do |key,value|
              elements << "#{value}"
              w << key
            end
            vt_cols = w
            sql = elements.join(',')

            fvt.syswrite(sql + "\r\n")

          end

        end
      end

    end

    fvc1.close
    fvc2.close
    frk.close
    fci.close
    fcb.close
    fvt.close
  
    execute_data_file(vc_cols,rk_cols,ci_cols,cb_cols,vt_cols)

end

def execute_data_file(vc_cols,rk_cols,ci_cols,cb_cols,vt_cols)

    STDERR.puts "--> Executing data test files ... "

    config   = Rails::Configuration.new
    m_host     = config.database_configuration[RAILS_ENV]["host"]
    m_database = config.database_configuration[RAILS_ENV]["database"]
    m_username = config.database_configuration[RAILS_ENV]["username"]
    m_password = config.database_configuration[RAILS_ENV]["password"]

    STDERR.puts " Connecting to #{m_host} ..."
    STDERR.puts " Connecting database #{m_database} ..."
    
    target_dir = "/tmp"
    voice_log_file1 = "#{target_dir}/voice_logs_1.sql"
    voice_log_file2 = "#{target_dir}/voice_logs_2.sql"
    result_keyword_file = "#{target_dir}/result_keywords.sql"
    call_info_file = "#{target_dir}/call_informations.sql"
    call_bookmark = "#{target_dir}/call_bookmarks.sql"
    voice_log_counters = "#{target_dir}/voice_log_counters.sql"

    if File.exist?(voice_log_file1)

      File.chmod(0777,voice_log_file1)
      File.chmod(0777,voice_log_file2)

      #STDERR.puts "--> Updating voice logs 0 ... #{voice_log_file}"
      #cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{vc_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{voice_log_file}"
      #system cmd

      File.rename(voice_log_file1,voice_log_file1.gsub("voice_logs_1.sql","voice_logs_today_1.sql"))
      voice_log_file1 = voice_log_file1.gsub("voice_logs_1.sql","voice_logs_today_1.sql")
      STDERR.puts "--> Updating voice logs 1 ... #{voice_log_file1}"
      cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{vc_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{voice_log_file1}"
      system cmd
   
      File.rename(voice_log_file2,voice_log_file2.gsub("voice_logs_2.sql","voice_logs_today_2.sql"))
      voice_log_file2 = voice_log_file2.gsub("voice_logs_2.sql","voice_logs_today_2.sql")
      STDERR.puts "--> Updating voice logs 2 ... #{voice_log_file2}"
      cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{vc_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{voice_log_file2}"
      #system cmd
      
      STDERR.puts "--> Deleting voice logs temp file ... "
      File.delete(voice_log_file1)
      File.delete(voice_log_file2)

      #STDERR.puts "--> Updating agent_id 0 to NULL"
      #ActiveRecord::Base.connection.execute("UPDATE voice_logs_today_1 SET agent_id = NULL WHERE agent_id = 0")
      #ActiveRecord::Base.connection.execute("UPDATE voice_logs_today_2 SET agent_id = NULL WHERE agent_id = 0")
      
    end
    if File.exist?(result_keyword_file)

      STDERR.puts "--> Updating result keywords ... "
      cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{rk_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{result_keyword_file}"
      system cmd

      STDERR.puts "--> Deleting result keywords temp file ... "
      File.delete(result_keyword_file)

    end
    if File.exist?(call_info_file)

      STDERR.puts "--> Updating call informations ... "
      cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{ci_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{call_info_file}"
      system cmd

      STDERR.puts "--> Deleting call informations temp file ... "
      File.delete(call_info_file)

    end
    if File.exist?(call_bookmark)

      STDERR.puts "--> Updating call bookmark ... "
      cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{cb_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{call_bookmark}"
      system cmd

      STDERR.puts "--> Deleting call bookmark temp file ... "
      File.delete(call_bookmark)

    end
    if File.exist?(voice_log_counters)

      STDERR.puts "--> Updating voice counter ... "
      cmd = "mysqlimport -u #{m_username} -ppassword  -h #{m_host} --fields-terminated-by=\",\" --columns=#{vt_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{voice_log_counters}"
      #system cmd

      STDERR.puts "--> Deleting voice counter temp file ... "
      File.delete(voice_log_counters)

    end
    
    cmd = ""
  
    STDERR.puts "--> Updating voice logs finish ... "

end

def compare_voice_logs
    
    AmiTool.check_voice_log_tables()
    
    STDOUT.puts "Merge VoiceLogs Table .."

    # check target
    
    tbl_no = AmiConfig.get('client.aohs_web.activeId').to_i
    tbl_no = 1 if tbl_no <= 0
    VoiceLogToday.set_table_name("voice_logs_today_#{tbl_no}")

    vl_today_count = VoiceLogToday.count(:id)

    if vl_today_count > 0
      
      today = Date.today
      min_date = VoiceLogToday.minimum(:start_time).to_date
      max_date = VoiceLogToday.maximum(:start_time).to_date
      
      if min_date > today
        min_date = today
      end
      
      STDOUT.puts " => Start From #{min_date} To #{max_date}"

      while min_date <= max_date

          table_name = "voice_logs_#{min_date.strftime("%Y%m")}"

          STDOUT.puts " -> Update Date_at: #{min_date}"
          STDOUT.puts " -> Target Table: #{table_name}"

          vls = VoiceLogToday.find(:all,:conditions => "start_time between '#{min_date} 00:00:00' and '#{min_date} 23:59:59'",:order => 'start_time asc')
  
          STDOUT.puts " -> Updating ..."
          
          unless vls.empty?
            while not vls.empty?
              vl = vls.pop
              a = []
              b = []
              vl.attributes.each_pair { |k,v|
                  a << k
                  if v.is_a?(Time)
                      b << "'#{v.strftime("%Y-%m-%d %H:%M:%S")}'"
                  else
                      b << "'#{v}'"
                  end
              }

              old_vl = VoiceLog.find(:first,:conditions => {:id => vl.id,:call_id => vl.call_id})
              if old_vl.nil?
                ins_sql = "INSERT INTO #{table_name} (#{a.join(',')}) VALUES(#{b.join(',')});"
                ActiveRecord::Base.connection.insert(ins_sql)
              else
                STDERR.puts "Duplicate voice_logs: INSERT INTO #{table_name} (#{a.join(',')}) VALUES(#{b.join(',')});"
              end

            end
          end

          vls = []

          STDOUT.puts " -> Deleting ..."
          
          # delete data was copied.
          VoiceLogToday.delete_all("start_time between '#{min_date} 00:00:00' and '#{min_date} 23:59:59'")

          min_date = min_date + 1

      end

    end

    max_id = VoiceLog.maximum(:id).to_i
    max_id = max_id + 1
    
    STDOUT.puts "Maximum id : #{max_id}"

    ['voice_logs_today_1','voice_logs_today_2'].each do |t|
      STDOUT.puts "Deleted->#{t}"
      ActiveRecord::Base.connection.execute("DELETE FROM #{t};")
      ActiveRecord::Base.connection.execute("ALTER TABLE #{t} AUTO_INCREMENT = #{max_id};")
    end



    STDOUT.puts "Merge Finished"
    
end