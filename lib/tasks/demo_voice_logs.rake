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
        create_voice_logs(-1)
        #create_voice_logs(0)
        
        #create_voice_logs2(0)
        #create_voice_logs(1)
      end
    
      desc 'Compare'
      task :compare => :setup do
        compare_voice_logs
      end
    
   end

end

def remove_voice_logs

   STDERR.puts "--> Removing voice log and reference table"

   targets = [VoiceLog, ResultKeyword, CallInformation, CallBookmark, DailyStatistics,WeeklyStatistics,MonthlyStatistics,VoiceLogTemp]
   targets.each do |m|
      m.delete_all
      STDERR.puts "#{m} is deleted all"
   end

end

def create_voice_logs(num_of_months)

  $NUMBER_OF_MONTHS = num_of_months             # 0 is TODAY, x < 0 is PAST and TODAY, x > 0 is TOMORROW and FUTURE
  $NUMBER_OF_CALLS_PER_AGENT_PER_DAY = 5
  $NUMBER_OF_AGENT_HOLIDAY = 10
  $MAX_CALL_DURATION = 650
  $MIN_CALL_DURATION = 30
  $BETWEEN_CALL_TIME = 45
  $BETWEEN_CALL_TIME_DEFAULT = 5
  $VOICES = voices = ['001.wav','002.wav','003.wav']
  $IF_KEYWORDS = true
 
  customer_names = []
  customer_names_file = File.join(File.dirname(__FILE__),"FIRST_NAME.txt")
  File.open(customer_names_file).each do |line|
    customer_names << "#{line.to_s.strip}".downcase
  end
  
  customer_phones = []
  CustomerNumber.all.each do |p|
    customer_phones << p.number
  end
  
  target_dir = "/tmp"
  voice_log_file = "#{target_dir}/voice_logs.sql"
  voice_log_file1 = "#{target_dir}/voice_logs_1.sql"
  voice_log_file2 = "#{target_dir}/voice_logs_2.sql"
  result_keyword_file = "#{target_dir}/result_keywords.sql"
  call_info_file = "#{target_dir}/call_informations.sql"
  call_bookmark = "#{target_dir}/call_bookmarks.sql"
  voice_log_counters = "#{target_dir}/voice_log_counters.sql"
  xfer_logs_file = "#{target_dir}/xfer_logs.dat"
  
  if File.exist?(voice_log_file)
    File.delete(voice_log_file)
  end
  if File.exist?(voice_log_file1)
    File.delete(voice_log_file1)
  end
  if File.exist?(voice_log_file2)
    File.delete(voice_log_file2)
  end
  if File.exist?(xfer_logs_file)
    File.delete(xfer_logs_file)
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

  fvc = File.new(voice_log_file, "a")
  fvc1 = File.new(voice_log_file1, "a")
  fvc2 = File.new(voice_log_file2, "a")
  frk = File.new(result_keyword_file, "a")
  fci = File.new(call_info_file, "a")
  fcb = File.new(call_bookmark, "a")
  fvt = File.new(voice_log_counters, "a")
  fxf = File.new(xfer_logs_file, "a")
  
  STDERR.puts "--> Creating voice logs ..."

    agents = Agent.find(:all)
    managers = Manager.find(:all)
    #agents = agents.concat(managers)
  
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
    xfer_id = 0
    
    vc_cols = []
    rk_cols = []
    ci_cols = []
    cb_cols = []
    vt_cols = []
    xf_cols = []
    
    STDERR.puts "   -> creating voice log from #{log_start_date} to #{log_end_date}"

    periods = (log_start_date..log_end_date).to_a

    periods.each do |start_date|

      STDERR.puts "   -> logs date : #{start_date.strftime('%Y-%m-%d')} : [#{call_counter}]"

      agents.each do |agent|
	    next if rand(14) == 6
        if true
          agent_name = agent.display_name
          agent_id = agent.id
          group_name = (agent.group.nil? ? "" : agent.group.name)
          group_id = (agent.group.nil? ? 0 : agent.group.id)

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
            
            case rand(3)
            when 0
              ani = '08' + sprintf('%08d',rand(100000))
            when 1
              ani = '02' + sprintf('%07d',rand(100000))
            else
              ani = '0' + (rand(7) + 1).to_s + sprintf('%07d',rand(100000)) 
            end
            
            dnis = '02' + sprintf('%07d',rand(100000))
            extension = '1' + sprintf('%03d',rand(1000))

            if rand(10) == 0 or rand(10) == 1
              duration = rand($MAX_CALL_DURATION) + 30
            else
              duration = rand($MIN_CALL_DURATION) + 30
            end

            hangup_cause = 14
            call_reference = rand(255)
            disposition = "http://192.168.1.17/voice_data/#{voices[rand(voices.length-1)]}"
            customer = sprintf("#{customer_names[rand(customer_names.length)]}-%03d",rand(999))

            if rand(10000) == 3
              call_direction = ["e","u"][rand(2)]
            else
              call_direction = ["i","o"][rand(2)]
            end
            
            if (rand(50) < 30) and (customer_phones.length > 0)
              case call_direction
                when 'i'
                  ani = customer_phones[rand(customer_phones.length)]  
                when 'o'
                  dnis = customer_phones[rand(customer_phones.length)]
              end
            end
            ##call_direction = 'o'
            
            updated_at = Time.now
            created_at = updated_at
            call_time = "#{start_date.strftime("%Y-%m-%d")} #{start_time.strftime("%H:%M:%S")}"
            
            call_id = "#{sprintf('%015d',rand(1000000000000000))}#{sprintf('%010d',voice_log_id)}"
            
            voice_log = {
                      :id => voice_log_id,
                      :system_id => system_id,
                      :device_id => device_id,
                      :channel_id => channel_id,
                      :ani => ani,
                      :dnis => dnis,
                      :extension => extension,
                      :start_time => call_time,
                      :duration => duration,
                      :hangup_cause => hangup_cause,
                      :call_reference => call_reference,
                      :agent_id => (rand(1000) == 500 ? "\N" : agent_id),
                      :voice_file_url => disposition,
                      :call_direction => call_direction,
                      :digest => Digest::MD5.hexdigest("#{voice_log_id}-#{call_direction}-#{agent_id}"),
                      :call_id => call_id,
                      :site_id => rand(4),
                      
                      :ori_call_id => 1,
                      :flag_tranfer => nil,
                      :xfer_ani => nil,
                      :xfer_dnis => nil,
                      :log_trans_ani => nil,
                      :log_trans_dnis => nil,
                      :log_trans_extension => nil
                     }
            voice_log_counter = {
                      :id => voice_log_id,
                      :voice_log_id => voice_log_id,
                      :keyword_count => 0,
                      :ngword_count => 0,
                      :mustword_count => 0,
                      :bookmark_count => 0
                    }
                    
            transfers_calls = []
            tran_call = nil
            trnans_count = rand(3)
            
            original_call_id = call_id
            
            trnans_count.times do |c|      
              if tran_call.nil?
                prev_vlog = voice_log.clone
                voice_log[:ori_call_id] = 1
                call_direction = 'i'
              else
                prev_vlog = tran_call.clone
                call_direction = 'i'
              end
              
              voice_log_id = voice_log_id + 1

              case rand(3)
              when 0
                new_phone = '08' + sprintf('%08d',rand(100000))
              when 1
                new_phone = '02' + sprintf('%07d',rand(100000)) 
              else
                new_phone = '0' + (rand(7) + 1).to_s + sprintf('%07d',rand(100000)) 
              end
            
              channel_id = rand(1000)             
              trans_phone = new_phone
              trans_ext = '1' + sprintf('%03d',rand(1000))
              trans_agent_id = agents[rand(agents.length)].id
              call_time = (Time.parse(prev_vlog[:start_time]) + prev_vlog[:duration]).strftime("%Y-%m-%d %H:%M:%S")
              new_call_id = "#{sprintf('%015d',rand(1000000000000000))}#{sprintf('%010d',voice_log_id)}"
              
              prev_vlog[:flag_tranfer] =  "Conn"
              prev_vlog[:xfer_ani] = ((call_direction == 'i') ? prev_vlog[:dnis] : trans_phone)
              prev_vlog[:xfer_dnis] = ((call_direction == 'i') ? trans_phone : prev_vlog[:dnis])
              
              prev_vlog[:log_trans_ani] = prev_vlog[:xfer_ani]
              prev_vlog[:log_trans_dnis] = prev_vlog[:xfer_dnis]
              prev_vlog[:log_trans_extension] = trans_ext
              
              tran_call = {
                      :id => voice_log_id,
                      :system_id => system_id,
                      :device_id => device_id,
                      :channel_id => channel_id,
                      :ani => prev_vlog[:xfer_ani],
                      :dnis => prev_vlog[:xfer_dnis],
                      :extension => trans_ext,
                      :start_time => call_time,
                      :duration => duration + rand(100),
                      :hangup_cause => hangup_cause,
                      :call_reference => call_reference,
                      :agent_id => (rand(1000) == 500 ? "\N" : trans_agent_id),
                      :voice_file_url => disposition,
                      :call_direction => call_direction,
                      :digest => Digest::MD5.hexdigest("#{voice_log_id}-#{call_direction}-#{agent_id}"),
                      :call_id => new_call_id,
                      :site_id => rand(4),
                      :ori_call_id => original_call_id, 
                      :flag_tranfer => ((trnans_count >= c) ? "New" : "Conn"), 
                      :xfer_ani => nil,
                      :xfer_dnis => nil,
                      :log_trans_ani => nil,
                      :log_trans_dnis => nil,
                      :log_trans_extension => nil
                      }
                      
                      xfer_id = xfer_id + 1
                      xfer_log = {
                        :id => xfer_id,
                        :xfer_start_time => call_time,
                        :xfer_ani => prev_vlog[:xfer_ani],
                        :xfer_dnis => prev_vlog[:xfer_dnis],
                        :xfer_extension => trans_ext,
                        :xfer_call_id1 => prev_vlog[:call_id],
                        :xfer_call_id2 => new_call_id,
                        :updated_on => call_time,
                        :msg_type => 1,
                        :mapping_status => nil, 
                        :sender => nil,
                        :ip => nil
                      }
                      #Fixed time
                      start_time = Time.parse(call_time)
                      transfers_calls << tran_call

                      w = []
                      elements = []
                      xfer_log.each do |key,value|
                        elements << "#{value}"
                        w << key
                      end
                      xf_cols = w
                      sql = elements.join(',')

                      #fxf.syswrite(sql + "\r\n")
                   
                 ## make keywords
                 stime, etime = 0, 0
                 rand(3).times do 
                    stime = stime + rand(100)
                    etime = stime + rand(100)
                    
                    if $IF_KEYWORDS                  
                      keyword = keywords[rand(keywords.length-1)]
                      keyword_type = keyword.keyword_type.to_s
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
                    end
                 end
            end
            
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
                when 0,1,2
                  
                    if $IF_KEYWORDS                  
                      keyword = keywords[rand(keywords.length-1)]
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
                    end
                  
                when 6,7
                    if false
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
  
                      #fci.syswrite(sql + "\r\n")
                    end 
                when 8,9
            bk_list = ["คุยนอกเรื่อง--โทรดูดวงกับหมดดู","คุยนอกเรื่อง--โทรเ่ล่นหุ้น","คุยนอกเรื่อง--ใช้โทรศัพท์คุยหาแฟน","ข่มขู่ลูกค้า--พูดจาข่มขู่ดูถูกลูกค้าเกินไป","ต่อว่าพนักงาน--ต่อว่าพนักงานรับสายพูดจาหยาบคาย","หนักงานให้มูลผิด--ให้ข้อมูลลูกค้าผิด ไม่ตรงกับความเป็นจริง"][rand(6)]
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

      fvc.syswrite(sql + "\r\n")
      #if rand(10) == 11
      fvc1.syswrite(sql + "\r\n")
      #else
      # fvc1.syswrite(sql + "\r\n")
      # fvc2.syswrite(sql + "\r\n")     
      #end
           
            transfers_calls.each do |tc|
              sql = nil
               elements = []
              tc.each do |key,value|
                elements << "#{value}"
              end
              sql = elements.join(',')
              fvc.syswrite(sql + "\r\n")
              fvc1.syswrite(sql + "\r\n")
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
    
    fvc.close
    fvc1.close
    fvc2.close
    frk.close
    fci.close
    fcb.close
    fvt.close
    fxf.close
    
    execute_data_file(vc_cols,rk_cols,ci_cols,cb_cols,vt_cols,xf_cols)

end

def execute_data_file(vc_cols,rk_cols,ci_cols,cb_cols,vt_cols,xf_cols)

    STDERR.puts "--> Executing data test files ... "

    config   = Rails.configuration
    m_host     = config.database_configuration[RAILS_ENV]["host"]
    m_database = config.database_configuration[RAILS_ENV]["database"]
    m_username = config.database_configuration[RAILS_ENV]["username"]
    m_password = config.database_configuration[RAILS_ENV]["password"]

    STDERR.puts " Connecting to #{m_host} ..."
    STDERR.puts " Connecting database #{m_database} ..."
    
    target_dir = "/tmp"
    voice_log_file = "#{target_dir}/voice_logs.sql"
    voice_log_file1 = "#{target_dir}/voice_logs_1.sql"
    voice_log_file2 = "#{target_dir}/voice_logs_2.sql"
    result_keyword_file = "#{target_dir}/result_keywords.sql"
    call_info_file = "#{target_dir}/call_informations.sql"
    call_bookmark = "#{target_dir}/call_bookmarks.sql"
    voice_log_counters = "#{target_dir}/voice_log_counters.sql"
    xfer_log_file = "#{target_dir}/xfer_logs.dat"
    
    if File.exist?(voice_log_file1)

      File.chmod(0777,voice_log_file)
      File.chmod(0777,voice_log_file1)
      File.chmod(0777,voice_log_file2)

      #STDERR.puts "--> Updating voice logs 0 ... #{voice_log_file}"
      #cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{vc_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{voice_log_file}"
      #system cmd

      File.rename(voice_log_file1,voice_log_file1.gsub("voice_logs_1.sql","voice_logs_today.sql"))
      voice_log_file1 = voice_log_file1.gsub("voice_logs_1.sql","voice_logs_today.sql")
      STDERR.puts "--> Updating voice logs 1 ... #{voice_log_file1}"
      cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{vc_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{voice_log_file1}"
      system cmd
      
      
      File.rename(voice_log_file2,voice_log_file2.gsub("voice_logs_2.sql","voice_logs_today_2.sql"))
      voice_log_file2 = voice_log_file2.gsub("voice_logs_2.sql","voice_logs_today_2.sql")
      STDERR.puts "--> Updating voice logs 2 ... #{voice_log_file2}"
      #cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{vc_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{voice_log_file2}"
      #system cmd
      
      STDERR.puts "--> Deleting voice logs temp file ... "
      File.delete(voice_log_file1)
      File.delete(voice_log_file2)

      #STDERR.puts "--> Updating agent_id 0 to NULL"
      #ActiveRecord::Base.connection.execute("UPDATE voice_logs_today_1 SET agent_id = NULL WHERE agent_id = 0")
      #ActiveRecord::Base.connection.execute("UPDATE voice_logs_today_2 SET agent_id = NULL WHERE agent_id = 0")
      
      STDERR.puts "Updating voice_log_today..."
      ActiveRecord::Base.connection.execute("UPDATE voice_logs_today SET site_id = 9")
      
    end
    if File.exist?(xfer_log_file)
      
      STDERR.puts "--> Updating xfer logs ... #{xfer_log_file}"
      cmd = "mysqlimport -u #{m_username} -ppassword -h #{m_host} --fields-terminated-by=\",\" --columns=#{xf_cols.join(',')} --lines-terminated-by=\"\r\n\" #{m_database} #{xfer_log_file}"
      system cmd  
            
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

def create_voice_logs2(num_of_months)

  $NUMBER_OF_MONTHS = num_of_months             # 0 is TODAY, x < 0 is PAST and TODAY, x > 0 is TOMORROW and FUTURE
  $NUMBER_OF_CALLS_PER_AGENT_PER_DAY = 5
  $NUMBER_OF_AGENT_HOLIDAY = 10
  $MAX_CALL_DURATION = 900
  $MIN_CALL_DURATION = 60
  $BETWEEN_CALL_TIME = 90
  $BETWEEN_CALL_TIME_DEFAULT = 5
  $VOICES = voices = ['001.wav','002.wav','003.wav']
  $IF_KEYWORDS = true
  
    call_counter = 0
    voice_log_id = 0
    result_keyword_id = 0
    call_info_id = 0
    call_bookmark_id = 0
    xfer_id = 0
  
  customer_names = []
  customer_names_file = File.join(File.dirname(__FILE__),"FIRST_NAME.txt")
  File.open(customer_names_file).each do |line|
    customer_names << "#{line.to_s.strip}".downcase
  end
  
  customer_phones = []
  CustomerNumber.all.each do |p|
    customer_phones << p.number
  end
  
  target_dir = "/tmp"
  voice_log_file = "#{target_dir}/voice_logs.sql"
  voice_log_file1 = "#{target_dir}/voice_logs_1.sql"
  voice_log_file2 = "#{target_dir}/voice_logs_2.sql"
  result_keyword_file = "#{target_dir}/result_keywords.sql"
  call_info_file = "#{target_dir}/call_informations.sql"
  call_bookmark = "#{target_dir}/call_bookmarks.sql"
  voice_log_counters = "#{target_dir}/voice_log_counters.sql"
  xfer_logs_file = "#{target_dir}/xfer_logs.dat"
  
  STDERR.puts "--> Creating voice logs ..."

    agents = Agent.find(:all)
    managers = Manager.find(:all)
  
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
          ta = Time.new
          1.upto(number_of_calls_per_day) do |i|
            
            te = Time.new
            STDOUT.puts ": #{(te - ta)}" 
            ta = te
            
            #STDERR.puts "   -> logs date : #{start_date.strftime('%Y-%m-%d')} : [#{call_counter}]" if call_counter%1000 == 0

            start_time += (duration + $BETWEEN_CALL_TIME_DEFAULT + rand($BETWEEN_CALL_TIME))
            if rand(10) == 7
              start_time += 500
            end

            call_counter += 1
            system_id = rand(3)
            device_id = rand(360)
            channel_id = rand(1000)
            
            case rand(3)
            when 0
              ani = '08' + sprintf('%08d',rand(100000))
            when 1
              ani = '02' + sprintf('%07d',rand(100000))
            else
              ani = '0' + (rand(7) + 1).to_s + sprintf('%07d',rand(100000)) 
            end
            
            dnis = '02' + sprintf('%07d',rand(100000))
            extension = '1' + sprintf('%03d',rand(1000))

            if rand(10) == 0 or rand(10) == 1
              duration = rand($MAX_CALL_DURATION) + 30
            else
              duration = rand($MIN_CALL_DURATION) + 30
            end

            hangup_cause = 14
            call_reference = rand(255)
            disposition = "http://192.168.1.17/voice_data/#{voices[rand(voices.length-1)]}"
            customer = sprintf("#{customer_names[rand(customer_names.length)]}-%03d",rand(999))

            if rand(10000) == 3
              call_direction = ["e","u"][rand(2)]
            else
              call_direction = ["i","o"][rand(2)]
            end
            
            if (rand(50) < 30) and (customer_phones.length > 0)
              case call_direction
                when 'i'
                  ani = customer_phones[rand(customer_phones.length)]  
                when 'o'
                  dnis = customer_phones[rand(customer_phones.length)]
              end
            end
            ##call_direction = 'o'
            
            updated_at = Time.now
            created_at = updated_at
            call_time = "#{start_date.strftime("%Y-%m-%d")} #{start_time.strftime("%H:%M:%S")}"
            
            call_id = "#{sprintf('%015d',rand(1000000000000000))}#{sprintf('%010d',voice_log_id)}"
            
            voice_log = {
                      :system_id => system_id,
                      :device_id => device_id,
                      :channel_id => channel_id,
                      :ani => ani,
                      :dnis => dnis,
                      :extension => extension,
                      :start_time => call_time,
                      :duration => duration,
                      :hangup_cause => hangup_cause,
                      :call_reference => call_reference,
                      :agent_id => (rand(1000) == 500 ? "\N" : agent_id),
                      :voice_file_url => disposition,
                      :call_direction => call_direction,
                      :digest => Digest::MD5.hexdigest("#{voice_log_id}-#{call_direction}-#{agent_id}"),
                      :call_id => call_id,
                      :site_id => rand(4),
                      
                      :ori_call_id => 1,
                      :flag_tranfer => nil,
                      :xfer_ani => nil,
                      :xfer_dnis => nil,
                      :log_trans_ani => nil,
                      :log_trans_dnis => nil,
                      :log_trans_extension => nil
            }
                    
            v = VoiceLogToday.new(voice_log)
            v.save!
            v.update_attributes(:site_id => rand(20))
            voice_log_id = v.id
                    
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
                when 0,1,2
                    if $IF_KEYWORDS                  
                      keyword = keywords[rand(keywords.length-1)]
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
                      rk = ResultKeyword.new(resultkeyword)
                      rk.save!
                    end
               end # end case
           end # end range
          end
        end
      end

    end 
    
end # end def