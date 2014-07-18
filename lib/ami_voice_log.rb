module AmiVoiceLog
  
  def self.repair_voice_log_counters_all
    
    start_day = VoiceLogTemp.minimum(:start_time).to_date || Date.today
    end_day = VoiceLogTemp.maximum(:start_time).to_date || Date.today
    
    repair_voice_log_counters(start_day,end_day)
  
  end
  
  def self.repair_voice_log_counters_daily
    
    # yesterday
    yesterday = Date.today - 1
    repair_voice_log_counters(yesterday,yesterday)
    
    # x 3 2 1=today
    that_day = (Date.today - 1) - Aohs::NUMBER_OF_RECENT_DAY_FOR_RPVLC
    repair_voice_log_counters(that_day,that_day)
    
  end
  
  def self.repair_voice_log_counters_weekly
    
    yesterday = Date.today - 1
    repair_voice_log_counters(yesterday.beginning_of_week,yesterday)
    
  end
  
  def self.repair_voice_log_counters_on(p) 
	
	case p.to_s
	when /^(\d\d\d\d\d\d\d\d)/
		STDOUT.puts "[VoiceLogCounter] - Param=YYYYMMDD"
		end_day = start_day = Date.parse(p)
		repair_voice_log_counters(start_day,end_day)
	when /^(\d\d\d\d\d\d)/
	    STDOUT.puts "[VoiceLogCounter] - Param=YYYYMM"
		start_day = Date.parse(p + "01") 
		end_day = start_day.end_of_month
		repair_voice_log_counters(start_day,end_day)		
	when /^(\d\d\d\d)/
		STDOUT.puts "[VoiceLogCounter] - Param=YYYY"
		start_day = Date.parse(p + "0101")
		end_day = Date.parse(p + "1231")
		repair_voice_log_counters(start_day,end_day)
	else
		STDOUT.puts "[VoiceLogCounter] - Param Wrong=YYYYMMDD|YYYYMM|YYYY"
	end
	
  end
  
  def self.repair_voice_log_counters(start_day=nil,end_day=nil)

    STDOUT.puts "[VoiceLogCounter] - repair voice_log_counters data"

    if not start_day.nil? and not end_day.nil?
      start_date = start_day
      end_date = end_day
    else
      start_date = VoiceLogTemp.minimum(:start_time).to_date || Date.today
      end_date = VoiceLogTemp.maximum(:start_time).to_date || Date.today       
    end

    STDOUT.puts "[VoiceLogCounter] - checking data from #{start_date} to #{end_date}"
    
    (start_date..end_date).to_a.each do |day|    
      
      t1 = Time.new
      
      voice_logs = VoiceLogTemp.where(["date(start_time) = ?",day]).group(:id).all
      
      STDOUT.puts "[VoiceLogCounter] - check date #{day} => #{voice_logs.length} records"
      
      voice_logs.each do |v|

        vlc = { :voice_log_id => v.id }    
        
        if Aohs::MOD_KEYWORDS
          sql1 = "SELECT " 
          sql1 << "SUM(IF(k.keyword_type='n',1,0)) AS ngword, "
          sql1 << "SUM(IF(k.keyword_type='m',1,0)) AS mustword "
          sql1 << "FROM result_keywords r JOIN keywords k "
          sql1 << "ON r.keyword_id = k.id "
          sql1 << "WHERE r.edit_status is null and k.deleted = false and r.voice_log_id = #{v.id} "
                    
          sql2 = "SELECT "
          sql2 << "SUM(IF(k.keyword_type='n',1,0)) AS ngword, "
          sql2 << "SUM(IF(k.keyword_type='m',1,0)) AS mustword "
          sql2 << "FROM edit_keywords e JOIN keywords k "
          sql2 << "ON e.keyword_id = k.id "
          sql2 << "WHERE e.edit_status in ('n','e') and k.deleted = false and e.voice_log_id = #{v.id} "
          
          sql = "SELECT SUM(r.ngword) AS ngword, SUM(r.mustword) AS mustword "
          sql << "FROM ((#{sql1}) UNION (#{sql2})) r "
          
          x = ResultKeyword.find_by_sql(sql).first
          mustword1 = x.mustword
          ngword1 = x.ngword
          
          vlc[:ngword_count] = ngword1.to_i
          vlc[:mustword_count] = mustword1.to_i
        end
      
        vlc[:bookmark_count] = CallBookmark.where("call_bookmarks.voice_log_id = #{v.id}").count

        if Aohs::MOD_CALL_TRANSFER
          transfer_call_count = v.transfer_call_count_by_type
          
          vlc[:transfer_duration] = transfer_call_count[:duration].to_i
          vlc[:transfer_call_count] = transfer_call_count[:total].to_i
          vlc[:transfer_in_count] = transfer_call_count[:total_in].to_i          
          vlc[:transfer_out_count] = transfer_call_count[:total_out].to_i
          
          if vlc[:transfer_call_count] > 0 and Aohs::MOD_KEYWORDS
            transfer_keyword_count = v.transfer_keywords_count_by_type
            vlc[:transfer_ng_count] = transfer_keyword_count[:total_ng].to_i
            vlc[:transfer_must_count] = transfer_keyword_count[:total_must].to_i   
          end
        end
        
        a = ActiveRecord::Base.connection.select_all("SELECT * FROM voice_log_counters WHERE voice_log_id = #{v.id}").first
        if a.nil?
          VoiceLogCounter.create!(vlc)
          STDOUT.puts "[VoiceLogCounter] - insert voice_log_id:#{v.id}\t" 
        else
          matched = true
          vlc.each do |x,y|
            if a[x.to_s].to_i != y.to_i
              # integer
              matched = false
              break;
            end
          end
          if not matched
            VoiceLogCounter.update(a["id"],vlc)
            STDOUT.puts "[VoiceLogCounter] - update voice_log_id:#{v.id}\t" 
          end
        end
        
      end
      
      STDOUT.puts "[VoiceLogCounter] - total time:#{(Time.new - t1)/60} min" 
      
    end
    
    STDOUT.puts "[VoiceLogCounter] - finished"
  
  end
  
  def self.remove_unknown_voicelogs_counter
    
    STDOUT.puts "[RemUnknownCounter] - remove unkonwn voice_log counter"
    
    sql = "SELECT vc.id "
    sql << "FROM voice_log_counters vc LEFT JOIN ((SELECT id FROM voice_logs_1) UNION (SELECT id FROM voice_logs_2)) v "
    sql << "ON vc.voice_log_id = v.id "
    sql << "WHERE v.id IS NULL "
    
    begin
      vc = VoiceLogCounter.find_by_sql(sql)
      STDOUT.puts "[RemUnknownCounter] - removed #{vc.length} records"
      unless vc.empty?
        VoiceLogCounter.delete(vc)
      end
    rescue => e
      STDOUT.puts "[RemUnknownCounter] - #{e.message}"
    end

    STDOUT.puts "[RemUnknownCounter] - finished"
    
  end
  
  def self.remove_duplicate_voicelogs_counter
    
  end
  
end
