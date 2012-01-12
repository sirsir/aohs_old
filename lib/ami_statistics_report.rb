require 'ami_log'
module AmiStatisticsReport
    
  def initial_statistics_setting

    wlog('[Statistics] get statistics configurations')

    $DAYS_OF_THE_WEEK = Aohs::DAYS_OF_THE_WEEK
    $DEFAULT_AGENT_ID = 0
    $KEYWORD_TYPES = Aohs::KEYWORDS_CODES
    $CALLDS = [nil].concat(Aohs::CALL_DIRECTION_CODES)
    
    $start_day_of_week = $DAYS_OF_THE_WEEK.index("#{AmiConfig.get('client.aohs_web.beginning_of_week')}").to_i
    wlog("[Statistics] -conf:aohs_web.beginning_of_week=#{$start_day_of_week}")
    $start_day_of_month = AmiConfig.get('client.aohs_web.beginning_of_month').to_i - 1
    wlog("[Statistics] -conf:aohs_web.beginning_of_month=#{$start_day_of_month}")

    # dis/enabled function
    
    @c_daily_v = Aohs::RUNSTACALL_DAILY
    @c_weekly_v = Aohs::RUNSTACALL_WEEKLY
    @c_monthly_v = Aohs::RUNSTACALL_MONTHLY
    @c_daily_k = Aohs::RUNSTAKEYW_DAILY
    @c_weekly_k = Aohs::RUNSTAKEYW_WEEKLY
    @c_monthly_k = Aohs::RUNSTAKEYW_MONTHLY
    
  end

  def get_statistics_type(target_model, calcurate_type, by_agent)
      condition_values = {
        :target_model => target_model.name, 
        :value_type => calcurate_type.to_s, 
        :by_agent => by_agent
      }
      statistics_type = StatisticsType.where(condition_values).first
      if statistics_type.nil?
        statistics_type = StatisticsType.new(condition_values)
        statistics_type.save
      end
      return statistics_type
  end
  
  def update_or_create_data(model_name,data)

    begin
      
      ## make conditions
      conditions = []
      data.each_pair do |f,v|
        next if f.to_s == "value"
        if v.nil?
          conditions << "#{model_name.table_name}.#{f.to_s} is null" 
        else
          conditions << "#{model_name.table_name}.#{f.to_s} = '#{v}'"
        end
      end
      
      ## remove duplicate records
      tmps = model_name.where(conditions.join(' and '))
      tmp = tmps.pop
      if not tmps.empty?
         tmps.each do |delt|
           delt.delete
         end
      end
    
      ## update or create new
      if tmp.nil?
        new_data = model_name.new(data)
        new_data.save!
      else
        if not (tmp.value.to_i == data[:value].to_i) # if value change
          model_name.update(tmp.id,data)
        end
      end
    rescue => e
      wlog("[Statistics] save information failed at #{model_name}->#{e.message}",false)
    end
    
  end

  def list_of_weeks(start_date,end_date=nil)

    all_weeks = []

    if end_date.nil? or (end_date > Date.today)
      end_date = Date.today
    end

    tmp_week = start_date.beginning_of_week + $start_day_of_week
    while tmp_week <= end_date
      all_weeks << tmp_week
      tmp_week = (tmp_week.end_of_week + 1).beginning_of_week + $start_day_of_week
    end

    return all_weeks
    
  end

  def list_of_months(start_date, end_date)

    all_months = []

    if end_date.nil? or (end_date > Date.today)
      end_date = Date.today
    end

    if start_date <= (start_date.beginning_of_month + $start_day_of_month)
      start_date = start_date.beginning_of_month - 1
    end

    tmp_month = start_date.beginning_of_month + $start_day_of_month
    while tmp_month <= end_date
      all_months << tmp_month
      tmp_month = (tmp_month.end_of_month + 1).beginning_of_month + $start_day_of_month
    end

    return all_months
    
  end

  def get_calc_date(models,reset=false)

    end_date = nil
    start_date = nil

    wlog("[Statistics] reset data => #{reset}")

    #reset = true
    # mode
    begin
      if reset == true
        start_date = VoiceLogTemp.minimum(:start_time).to_date rescue nil
        end_date = VoiceLogTemp.maximum(:start_time).to_date rescue nil
      else
        ststistisc_types = StatisticsType.where({:target_model => models.map { |m| m.class_name }})
        d = DailyStatistics.maximum(:start_day,:conditions => {:statistics_type_id => ststistisc_types.map { |s| s.id }})
        if d.nil?
          start_date = VoiceLogTemp.minimum(:start_time).to_date rescue nil
          end_date = VoiceLogTemp.maximum(:start_time).to_date rescue nil
        else
          start_date = d - 1
        end
      end
    rescue => e
      end_date = nil
      start_date = nil
    end
    
    start_date = Date.today if start_date.nil?
    end_date = Date.today if end_date.nil?
    
    end_date = Date.today - Aohs::RUNST_PROCESS_TO_XDAY if end_date.nil? or end_date >= Date.today
    start_date = Date.today - Aohs::RUNST_PROCESS_FROM_XDAY if end_date.nil? 
    
    if start_date >= end_date
      start_date = end_date     
    end
    
    wlog("[Statistics] checking data between #{start_date} and #{end_date}")
        
    return start_date, end_date
    
  end
  
  def get_repair_period(period,op={})
    
    start_day, end_day = Date.today, Date.today
    
    case period
    when :daily
      start_day = start_day - Aohs::NUMBER_OF_RECENT_DAY_FOR_RPSTC    
    when :weekly
      start_day = start_day.beginning_of_week
    when :monthly
      start_day = start_day.beginning_of_month
    when :all
      start_day = VoiceLogTemp.minimum(:start_time).to_date rescue Date.today 
    end
  
    return start_day, end_day
    
  end
  
  def wlog(message,result=true)
    STDOUT.puts Time.new.strftime("%Y/%m/%d %H:%M:%S") + " " + message.to_s
  end
  
  def remove_unknown_statistics_data
    
    # remove null statistics id
    # remove null agent_id and null keywords
    
    [DailyStatistics,WeeklyStatistics,MonthlyStatistics].each do |m|
      wlog("[Statistics] cleanup error data for #{m.table_name}")
      tmp = m.where("agent_id IS NULL and (keyword_id IS NULL or keyword_id <= 0)").all
      tmp.delete_all
      
      tmp = m.where("statistics_type_id IS NULL or statistics_type_id <= 0)").all
      tmp.delete_all
    end
    
  end

  def voice_logs_default_filter
	
	conditions = []
	
	v = VoiceLogTemp.table_name
	if Aohs::VFILTER_DURATION_MIN.to_i > 0
		conditions << "#{v}.duration >= #{Aohs::VFILTER_DURATION_MIN.to_i}"
	end
	
	return conditions
	
  end
  
  # ================================================================= # AGENT

  def daily_statistics_agents(target_model, calcurate_type, by_agent, start_date, end_date)
    
    wlog("[Statistics Call - Daily] batch is started")
    
    bln_success = true
    
    # call direction count
    
    $CALLDS.each do |cd|
      
      calc_type = (cd.nil? ? calcurate_type : (calcurate_type + ":" + cd)) 
      statistics_type = get_statistics_type( target_model, calc_type, by_agent )
      cd = ['i','o','e','u'] if cd.nil?
      
      wlog("[Statistics Call - Daily] model=#{target_model}, type=#{calc_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("[Statistics Call - Daily] period start from #{start_date} to #{end_date}, #{(start_date..end_date).to_a.length} days")
      wlog("[Statistics Call - Daily] resource table => #{target_model.name}")
      
      if by_agent
        
        filt_conds = voice_logs_default_filter
        
        daily_counts = VoiceLogTemp.select("agent_id, DATE(start_time) as start_date, count(id) as daily_count").where(["start_time BETWEEN ? AND ? AND call_direction in (?) AND duration >= ? ",start_date.to_s + " 00:00:00",end_date.to_s + " 23:59:59",cd,Aohs::VFILTER_DURATION_MIN]).group("agent_id, DATE(start_time)")
        daily_counts = daily_counts.where(filt_conds) unless filt_conds.empty?
        daily_counts = daily_counts.all
        
        i = 0
        unless daily_counts.empty?
          while not daily_counts.empty?
            item = daily_counts.pop
            update_or_create_data(DailyStatistics,{
                :start_day => item.start_date,
                :agent_id => item.agent_id,
                :keyword_id => nil,
                :value => item.daily_count,
                :statistics_type_id => statistics_type.id})
            i += 1
          end
        end
        wlog("[Statistics Call - Daily] data has been updated, #{i} records")
        
      end      
    end

    wlog("[Statistics Call - Daily] closing batch")

    return bln_success

  end

  def weekly_statistics_agents(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true
    
    wlog("[Statistics Call - Weekly] started")
    
    $CALLDS.each do |cd|
      
      calc_type = (cd.nil? ? calcurate_type : (calcurate_type + ":" + cd)) 
      statistics_type = get_statistics_type( target_model, calc_type, by_agent )
      weeks = list_of_weeks(start_date, end_date)
      
      wlog("[Statistics Call - Weekly] model=#{target_model}, type=#{calc_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("[Statistics Call - Weekly] period from #{start_date} to #{end_date}, #{weeks.length} weeks")
      wlog("[Statistics Call - Weekly] resource table => #{DailyStatistics.name}")    
      
      unless weeks.empty?
        weeks.each do |week|
          
          start_of_week = week
          end_of_week = week + $DAYS_OF_THE_WEEK.length - 1

          wlog("[Statistics Call - Weekly] week@#{sprintf("%02d",start_of_week.cweek)}, #{start_of_week} - #{end_of_week}")

          if by_agent  
            weekly_count = DailyStatistics.select('agent_id, sum(value) as weekly_count') 
            weekly_count = weekly_count.where("start_day between '#{start_of_week}' and '#{end_of_week}' and statistics_type_id = #{statistics_type.id} and agent_id >= 0").group("agent_id").all
            i = 0
            unless weekly_count.blank?
              while (not weekly_count.empty?)
                item = weekly_count.pop
                update_or_create_data(WeeklyStatistics,{
                        :cweek => start_of_week.cweek,
                        :cwyear => start_of_week.cwyear,
                        :start_day => start_of_week,
                        :agent_id => item.agent_id,
                        :keyword_id => nil,
                        :value => item.weekly_count,
                        :statistics_type_id => statistics_type.id})
                i += 1       
              end
              
            end
            wlog("[Statistics Call - Weekly] data has been updated, #{i} records")
          end
        
        end
      end            
    
    end
    
    wlog("[Statistics Call - Weekly] finished")

    return bln_success

  end

  def monthly_statistics_agents(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true
    
    wlog("[Statistics Call - Monthly] started")
    
    $CALLDS.each do |cd|
      
      calc_type = (cd.nil? ? calcurate_type : (calcurate_type + ":" + cd)) 
      statistics_type = get_statistics_type( target_model, calc_type, by_agent )   
      months = list_of_months(start_date, end_date)      
     
      wlog("[Statistics Call - Monthly] model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("[Statistics Call - Monthly] period from #{start_date} to #{end_date}, #{months.length} months ")
      wlog("[Statistics Call - Monthly] resource table => #{DailyStatistics.name}")
    
      unless months.empty?
        months.each do |month|

        start_month = month
        end_month = month.end_of_month + $start_day_of_month

        wlog("[Statistics Call - Monthly] month@#{start_month.strftime("%b")}, #{start_month} - #{end_month}")

        if by_agent

          monthly_count = DailyStatistics.select('agent_id,sum(value) as monthly_count')
          monthly_count = monthly_count.where("start_day between '#{start_month}' and '#{end_month}' and statistics_type_id = #{statistics_type.id}")
          monthly_count = monthly_count.group("agent_id").all
                    
          i = 0
          unless monthly_count.blank?
            while (not monthly_count.empty?)
              item = monthly_count.pop
              update_or_create_data(MonthlyStatistics,{
                   :start_day => start_month,
                   :agent_id => item.agent_id,
                   :keyword_id => nil,
                   :value => item.monthly_count,
                   :statistics_type_id => statistics_type.id})
              i += 1     
            end
          end
          wlog("[Statistics Call - Monthly] data has been updated, #{i} records")
        end
      end
    end    
    end
    
    wlog("[Statistics Call - Monthly] finished")

    return bln_success

  end

  def statistics_agents(calc_mode='all',op={})
    
    wlog("[Statistics Call] all batch will starting now")
    
    if op[:reset].nil?
      start_date, end_date = get_calc_date([VoiceLog])
    else
      start_date, end_date = get_calc_date([VoiceLog],true)
    end

    if ['daily','all'].include?(calc_mode) and @c_daily_v
      daily_statistics_agents(VoiceLog,'count',true,start_date, end_date)
    end
    if ['weekly','all'].include?(calc_mode) and @c_weekly_v
      weekly_statistics_agents(VoiceLog,'count',true,start_date, end_date)
    end
    if ['monthly','all'].include?(calc_mode) and @c_monthly_v
      monthly_statistics_agents(VoiceLog,'count',true,start_date, end_date)
    end  

  end

  def repair_statistics_agents(p=:daily,op={})
    
    wlog("[Statistics Call] - reparing started")
    
    start_date, end_date = get_repair_period(p)     
    daily_statistics_agents(VoiceLog,'count',true,start_date, end_date)

  end

  # ================================================================= # KEYWORDS

  def daily_statistics_keywords(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true

    wlog("[Statistics Keywords - Daily] batch started")
    
    if by_agent
      
      $KEYWORD_TYPES.each do |kt|
        
        new_calcurate_type = "#{calcurate_type}:#{kt}"
        statistics_type = get_statistics_type( target_model, new_calcurate_type, by_agent )  
        
        wlog("[Statistics Keywords - Daily]  model=#{target_model}, type=#{new_calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
        wlog("[Statistics Keywords - Daily]  period from #{start_date} to #{end_date}, #{(start_date..end_date).to_a.length} days")          
        wlog("[Statistics Keywords - Daily]  resource => #{ResultKeyword.name},#{EditKeyword.name}")
        
        keywords_id = Keyword.select('id').where({:keyword_type => kt, :deleted => false})
        
        unless keywords_id.empty?
          
          keywords_id = keywords_id.map { |k| k.id }
          
          sql1 = ""
          sql1 << "SELECT 'r1'as rs,v.agent_id,DATE(v.start_time) as start_date,count(r.id) as word_count "
          sql1 << "FROM #{VoiceLogTemp.table_name} v JOIN result_keywords r ON v.id = r.voice_log_id "
          sql1 << "WHERE r.keyword_id IN (#{keywords_id.join(',')}) AND r.edit_status IS NULL AND start_time BETWEEN '#{start_date} 00:00:00' AND '#{end_date} 23:59:59' "
          sql1 << "GROUP BY v.agent_id,DATE(start_time) "
          
          sql2 = ""
          sql2 << "SELECT 'r2'as rs,v.agent_id,DATE(v.start_time) as start_date,count(r.id) as word_count "
          sql2 << "FROM #{VoiceLogTemp.table_name} v JOIN edit_keywords r ON v.id = r.voice_log_id "
          sql2 << "WHERE r.keyword_id IN (#{keywords_id.join(',')}) AND r.edit_status IN ('n','e') AND start_time BETWEEN '#{start_date} 00:00:00' AND '#{end_date} 23:59:59' "
          sql2 << "GROUP BY v.agent_id,DATE(start_time) "
          
          sql3 = ""
          sql3 << "SELECT q3.agent_id,q3.start_date,sum(q3.word_count) as word_count "
          sql3 << "FROM ((#{sql1}) UNION (#{sql2})) q3 "
          sql3 << "GROUP BY q3.agent_id,q3.start_date "
          
          daily_count = VoiceLogTemp.find_by_sql(sql3)
          
          wlog("[Statistics Keywords - Daily]  found result #{daily_count.length} records")
          
          unless daily_count.empty?
            while (not daily_count.empty?)
              item = daily_count.pop
              update_or_create_data(DailyStatistics,{
                        :start_day => item.start_date,
                        :agent_id => item.agent_id.to_i,
                        :keyword_id => nil,
                        :value => item.word_count.to_i,
                        :statistics_type_id => statistics_type.id })             
            end
          end
          
        end
        
      end #end keyword
    
    else
      
      statistics_type = get_statistics_type( target_model, calcurate_type, by_agent )
      
      wlog("[Statistics Keywords - Daily]  model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("[Statistics Keywords - Daily]  period from #{start_date} to #{end_date}, #{(start_date..end_date).to_a.length} days")          
      wlog("[Statistics Keywords - Daily]  resource => #{ResultKeyword.name},#{EditKeyword.name}")
      
      keywords_id = Keyword.select('id').where({:deleted => false}) 
      keywords_id = keywords_id.map { |k| k.id }
      
      unless keywords_id.empty?
        
        sql1 = ""
        sql1 << "SELECT 'r1'as rs,r.keyword_id,DATE(start_time) as start_date,count(r.id) as word_count "
        sql1 << "FROM #{VoiceLogTemp.table_name} v JOIN result_keywords r ON v.id = r.voice_log_id "
        sql1 << "WHERE r.keyword_id IN (#{keywords_id.join(',')}) AND r.edit_status IS NULL AND start_time BETWEEN '#{start_date} 00:00:00' AND '#{end_date} 23:59:59' "
        sql1 << "GROUP BY r.keyword_id,DATE(start_time) "
        
        sql2 = ""
        sql2 << "SELECT 'r2'as rs,agent_id,DATE(start_time) as start_date,count(r.id) as word_count "
        sql2 << "FROM #{VoiceLogTemp.table_name} v JOIN edit_keywords r ON v.id = r.voice_log_id "
        sql2 << "WHERE r.keyword_id IN (#{keywords_id.join(',')}) AND r.edit_status IN ('n','e') AND start_time BETWEEN '#{start_date} 00:00:00' AND '#{end_date} 23:59:59' "
        sql2 << "GROUP BY r.keyword_id,DATE(start_time) "
        
        sql3 = ""
        sql3 << "SELECT q3.keyword_id,q3.start_date,sum(q3.word_count) as word_count "
        sql3 << "FROM ((#{sql1}) UNION (#{sql2})) q3 "
        sql3 << "GROUP BY q3.keyword_id,q3.start_date "
        
        daily_count = VoiceLogTemp.find_by_sql(sql3)
            
        wlog("[Statistics Keywords - Daily]  found result #{daily_count.length} records")   
        
        unless daily_count.empty?
          while not daily_count.empty?
            item = daily_count.pop
            update_or_create_data(DailyStatistics,{
                      :start_day => item.start_date,
                      :agent_id => nil,
                      :keyword_id => item.keyword_id,
                      :value => item.word_count.to_i,
                      :statistics_type_id => statistics_type.id })             
          end
        end
        
      end

    end
    
    wlog("[Statistics Keywords - Daily] finished ...")

    return bln_success

  end

  def weekly_statistics_keywords(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true

    wlog("[Statistics Keywords - Weekly] started")
    
    weeks = list_of_weeks(start_date, end_date)
    
    if by_agent
      
      $KEYWORD_TYPES.each do |kt|
        
        new_calcurate_type = "#{calcurate_type}:#{kt}"
        statistics_type = get_statistics_type( target_model, new_calcurate_type, by_agent )
        
        wlog("[Statistics Keywords - Weekly]  statisticsType model=#{target_model}, type=#{new_calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
        wlog("[Statistics Keywords - Weekly]  period from #{start_date} to #{end_date}, #{weeks.length} weeks")          
        wlog("[Statistics Keywords - Weekly]  resource => #{DailyStatistics.name}")
        
        unless weeks.empty?
          weeks.each do |week|
            
            start_week = week
            end_week = week + $DAYS_OF_THE_WEEK.length - 1            
            
            wlog("[Statistics Keywords - Weekly]  week@#{sprintf("%02d",start_week.cweek)}, #{start_week} - #{end_week}")
            
            weekly_count = DailyStatistics.select('agent_id,statistics_type_id,sum(value) as weekly_count')
            weekly_count = weekly_count.where("start_day between '#{start_week}' and '#{end_week}' and (keyword_id = 0 OR keyword_id IS NULL) and statistics_type_id = #{statistics_type.id}")
            weekly_count = weekly_count.group("agent_id,statistics_type_id").all
                        
            wlog("[Statistics Keywords - Weekly]  found result #{weekly_count.length} records")   
            
            unless weekly_count.empty?
              weekly_count.each do |item|
                update_or_create_data(WeeklyStatistics,{
                            :cweek => start_week.cweek,
                            :cwyear => start_week.cwyear,
                            :start_day => start_week,
                            :agent_id => item.agent_id,
                            :keyword_id => nil,
                            :value => item.weekly_count,
                            :statistics_type_id => statistics_type.id})
              end
            end             
                        
          end # end_week
        end 
        
      end # end_keyword
      
    else
      
      statistics_type = get_statistics_type( target_model, calcurate_type, by_agent )
      
      wlog("[Statistics Keywords - Weekly]  model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("[Statistics Keywords - Weekly]  period from #{start_date} to #{end_date}, #{weeks.length} weeks")          
      wlog("[Statistics Keywords - Weekly]  resource => #{DailyStatistics.name}")      
      
      unless weeks.empty?
        weeks.each do |week|
          
          start_week = week
          end_week = week + $DAYS_OF_THE_WEEK.length - 1       
        
          wlog("[Statistics Keywords - Weekly]  week@#{sprintf("%02d",start_week.cweek)}, #{start_week} - #{end_week}")
          
          weekly_count = DailyStatistics.select('keyword_id, sum(value) as weekly_count')
          weekly_count = weekly_count.where("start_day between '#{start_week}' and '#{end_week}' and statistics_type_id = #{statistics_type.id}")
          weekly_count = weekly_count.group('keyword_id').all

          wlog("[Statistics Keywords - Weekly]  found result #{weekly_count.length} records")  

          unless weekly_count.blank?
            weekly_count.each do |item|
                update_or_create_data(WeeklyStatistics,{
                            :cweek => start_week.cweek,
                            :cwyear => start_week.cwyear,
                            :start_day => start_week,
                            :agent_id => nil,
                            :keyword_id => item.keyword_id,
                            :value => item.weekly_count,
                            :statistics_type_id => statistics_type.id})
            end
          end   
        
        end # end_week
     end
     
    end

    wlog("[Statistics Keywords - Weekly] finished")

    return bln_success
  
  end

  def monthly_statistics_keywords(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true

    wlog("[Statistics Keywords - Monthly] started ...")
    
    months = list_of_months(start_date, end_date)
    
    if by_agent
      
      $KEYWORD_TYPES.each do |kt|
        
        new_calcurate_type = "#{calcurate_type}:#{kt}"
        statistics_type = get_statistics_type( target_model, new_calcurate_type, by_agent )
        
        wlog("[Statistics Keywords - Monthly]  model=#{target_model}, type=#{new_calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
        wlog("[Statistics Keywords - Monthly]  period from #{start_date} to #{end_date}, #{months.length} months")          
        wlog("[Statistics Keywords - Monthly]  resource => #{DailyStatistics.name}")
        
        unless months.empty?
          months.each do |month|
            
            start_month = month
            end_month = month.end_of_month + $start_day_of_month           
            
            wlog("[Statistics Keywords - Monthly]  month@#{start_month.strftime("%b")}, #{start_month} - #{end_month}")
            
            monthly_count = DailyStatistics.select('agent_id,statistics_type_id,sum(value) as monthly_count')
            monthly_count = monthly_count.where("start_day between '#{start_month}' and '#{end_month}' and statistics_type_id = #{statistics_type.id}")
            monthly_count = monthly_count.group("agent_id,statistics_type_id").all
                        
            wlog("[Statistics Keywords - Monthly]  found result #{monthly_count.length} records")   
            
            unless monthly_count.empty?
              monthly_count.each do |item|
                update_or_create_data(MonthlyStatistics,{
                  :start_day => start_month,
                  :agent_id => item.agent_id,
                  :keyword_id => nil,
                  :value => item.monthly_count,
                  :statistics_type_id => item.statistics_type_id})
              end
            end             
                        
          end # end_month
        end 
        
      end # end_keyword
      
    else
     
      statistics_type = get_statistics_type( target_model, calcurate_type, by_agent )
      
      wlog("[Statistics Keywords - Monthly]  statisticsType model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("[Statistics Keywords - Monthly]  period from #{start_date} to #{end_date}")          
      wlog("[Statistics Keywords - Monthly]  resource => #{DailyStatistics.name}")      
      
      unless months.empty?
        months.each do |month|
          
          start_month = month
          end_month = month.end_of_month + $start_day_of_month      
        
          wlog("[Statistics Keywords - Monthly]  month@#{start_month.strftime("%b")}, #{start_month} - #{end_month}")
          
          monthly_count = DailyStatistics.select('keyword_id,sum(value) as monthly_count')
          monthly_count = monthly_count.where("start_day between '#{start_month.strftime("%Y-%m-%d")}' and '#{end_month.strftime("%Y-%m-%d")}' and statistics_type_id = #{statistics_type.id}")
          monthly_count = monthly_count.group('keyword_id').all

          wlog("[Statistics Keywords - Monthly]  found result #{monthly_count.length} records")  

          unless monthly_count.empty?
            monthly_count.each do |item|
              update_or_create_data(MonthlyStatistics,{
                  :start_day => start_month,
                  :agent_id => nil,
                  :keyword_id => item.keyword_id,
                  :value => item.monthly_count,
                  :statistics_type_id => statistics_type.id})
            end

          end        
        
        end # end_month
     end
    
    end
    
    wlog("[Statistics Keywords - Monthly] finished ...")

    return bln_success

  end

  def statistics_keywords(calc_mode='all',op={})
    
    if Aohs::MOD_KEYWORDS 
      
      wlog("[Statistics Keywords] all batch will start now")
      
      if op[:reset].nil?
        start_date, end_date = get_calc_date([ResultKeyword])
      else
        start_date, end_date = get_calc_date([ResultKeyword],true)
      end
  
      if ['daily','all'].include?(calc_mode) and @c_daily_k
        daily_statistics_keywords(ResultKeyword,'sum',true,start_date, end_date)
        daily_statistics_keywords(ResultKeyword,'sum',false,start_date, end_date)
      end
      if ['weekly','all'].include?(calc_mode) and @c_weekly_k
        weekly_statistics_keywords(ResultKeyword,'sum',true,start_date, end_date)
        weekly_statistics_keywords(ResultKeyword,'sum',false,start_date, end_date)
      end
      if ['monthly','all'].include?(calc_mode) and @c_monthly_k
        monthly_statistics_keywords(ResultKeyword,'sum',true,start_date, end_date)
        monthly_statistics_keywords(ResultKeyword,'sum',false,start_date, end_date)
      end
  
    end
    
  end

  def repair_statistics_keywords(p=:daily,op={})
    
    if Aohs::MOD_KEYWORDS 
      
      wlog("[Statistics Keywords] reparing started")
      
      start_date, end_date = get_repair_period(p)   
      
      daily_statistics_keywords(ResultKeyword,'sum',true,start_date, end_date)
      daily_statistics_keywords(ResultKeyword,'sum',false,start_date, end_date)
      
    end
    
  end
    
  ##
  ##======================================================================== MAIN
  ##
  
  def statistics_clear
    
    wlog("Delete Statistics all")
    [DailyStatistics,WeeklyStatistics,MonthlyStatistics].each do |m|
     wlog(" - delete #{m.class_name}") 
      m.delete_all
    end
    
  end

  def statistics_main

    wlog("")
    wlog("Run Statistics")

    AmiLog.batch_log("Batch","StatisticsData/All",true,"option=none,type=all")
    
    initial_statistics_setting

    statistics_agents
    statistics_keywords
    
  end

  def statistics_main_repair

    wlog("")
    wlog("Run Statistics Repair")

    AmiLog.batch_log("Batch","StatisticsData/All",true,"option=reset,type=all")
    
    initial_statistics_setting

    statistics_agents('all',{:reset => true})
    statistics_keywords('all',{:reset => true})
    
  end
  
  def statistics_daily_repair
    
    AmiLog.batch_log("Batch","StatisticsData/All",true,"option=repair,type=all")
    
    initial_statistics_setting
    
    repair_statistics_agents  
    repair_statistics_keywords
   
  end

  def statistics_weekly_repair
    
    AmiLog.batch_log("Batch","StatisticsData/All",true,"option=repair,type=all")
    
    initial_statistics_setting
    
    repair_statistics_agents(:weekly)  
    repair_statistics_keywords(:weekly)
   
  end

  def statistics_all_repair
    
    AmiLog.batch_log("Batch","StatisticsData/All",true,"option=repair,type=all")
    
    initial_statistics_setting
    
    repair_statistics_agents(:all)  
    repair_statistics_keywords(:all)
   
  end  
  
  def statistics_main_agents

    AmiLog.batch_log("Batch","StatisticsData/Call",true,"option=none,type=call")
    
    initial_statistics_setting
    statistics_agents
    
  end

  def statistics_main_keywords

    AmiLog.batch_log("Batch","StatisticsData/Keyword",true,"option=none,type=keyword")
    
    initial_statistics_setting
    statistics_keywords
    
  end
  
end