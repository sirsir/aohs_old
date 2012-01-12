require 'ami_log'

module AmiStatisticsReport

  def initial_statistics_setting

    wlog('Get statistics configurations')

    $DAYS_OF_THE_WEEK = %w[mo tu we th fr sa su]
    $DEFAULT_AGENT_ID = 0
    $KEYWORD_TYPES = ['m','n','a']
    
    $start_day_of_week = $DAYS_OF_THE_WEEK.index("#{AmiConfig.get('client.aohs_web.beginning_of_week')}").to_i
    wlog("-conf:aohs_web.beginning_of_week=#{$start_day_of_week}")

    $start_day_of_month = AmiConfig.get('client.aohs_web.beginning_of_month').to_i - 1
    wlog("-conf:aohs_web.beginning_of_month=#{$start_day_of_month}")

    # dis/enabled function
    
    @c_daily_v = true
    @c_weekly_v = true
    @c_monthly_v = true
    @c_daily_k = true
    @c_weekly_k = true
    @c_monthly_k = true
    
  end

  def get_statistics_type(target_model, calcurate_type, by_agent)
      condition_values = {:target_model => target_model.class_name, :value_type => calcurate_type.to_s, :by_agent => by_agent}
      statistics_type = StatisticsType.find(:first,:conditions => condition_values)
      if statistics_type.nil?
        statistics_type = StatisticsType.new(condition_values)
        statistics_type.save
      end
      return statistics_type
  end

  def update_or_create_data(model_name,data)

    begin
      conditions = []
      data.each_pair do |f,v|
        if v.nil?
          conditions << "#{model_name.table_name}.#{f.to_s} is null" 
        else
          conditions << "#{model_name.table_name}.#{f.to_s} = '#{v}'"
        end
      end
      tmp = model_name.find(:first,:conditions => conditions.join(' and '))
      if tmp.nil?
        new_data = model_name.new(data)
        new_data.save!
      else
        if not (tmp.value.to_i == data[:value].to_i) # if value change
          model_name.update(tmp.id,data)
        end
      end
    rescue => e
      wlog("save failed at #{model_name}->#{e.message}",false)
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

    wlog("  - calc with reset => #{reset}")

    # mode
    begin
      if reset == true
        start_date = VoiceLogTemp.minimum(:start_time).to_date rescue nil
        end_date = VoiceLogTemp.maximum(:start_time).to_date rescue nil
      else
        ststistisc_types = StatisticsType.find(:all,:conditions => {:target_model => models.map { |m| m.class_name }})
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
    
    end_date = Date.today - 1 if end_date.nil? or end_date >= Date.today
    start_date = Date.today - 1 if end_date.nil? 
    
    if start_date >= end_date
      start_date = end_date     
    end
    
    wlog("  - calc date/time from #{start_date} -To #{end_date}")
    
    # For test
    #end_date = Date.today
    
    return start_date, end_date
    
  end
  
  def wlog(message,result=true)
    AmiLog.linfo(message)
  end
  
  # ================================================================= # AGENT

  def daily_statistics_agents(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true
    
    statistics_type = get_statistics_type( target_model, calcurate_type, by_agent )
    target_model = VoiceLogTemp
    
    wlog("[daily-agent] started ...")
    wlog("  - statistics_type => model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
    wlog("  - period from #{start_date} to #{end_date}")
    wlog("  - resource => #{target_model.class_name}")
    wlog("  - num_of_days => #{(start_date..end_date).to_a.length} days ")
    
    if by_agent

        daily_counts = target_model.find(
                      :all,
                      :select => "agent_id, DATE(start_time) as start_date, count(id) as daily_count",
                      :conditions => "start_time BETWEEN '#{start_date} 00:00:00' AND '#{end_date} 23:59:59'",
                      :group => "agent_id,DATE(start_time)")

        wlog("  - found result #{daily_counts.length} records")
        
        unless daily_counts.empty?
          while not daily_counts.empty?
            item = daily_counts.pop
            update_or_create_data(DailyStatistics,{
                :start_day => item.start_date,
                :agent_id => item.agent_id,
                :keyword_id => nil,
                :value => item.daily_count,
                :statistics_type_id => statistics_type.id})
          end
        end

    end

    wlog("[daily-agents] finished ...")

    return bln_success

  end

  def weekly_statistics_agents(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true
    
    statistics_type = get_statistics_type( target_model, calcurate_type, by_agent )
    
    wlog("[weekly-agents] started ...")
    wlog("  - statistics_type => model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
    wlog("  - period from #{start_date} to #{end_date}")
    wlog("  - resource => #{DailyStatistics.class_name}")
   
    weeks = list_of_weeks(start_date, end_date)
    wlog("  - num_of_weeks => #{weeks.length} weeks ")
    
    unless weeks.empty?
      weeks.each do |week|

        start_of_week = week
        end_of_week = week + $DAYS_OF_THE_WEEK.length - 1

        wlog("  - #{sprintf("%02d",start_of_week.cweek)}, #{start_of_week} - #{end_of_week}")

        if by_agent

          weekly_count = DailyStatistics.find(
                        :all,
                        :select => 'agent_id, sum(value) as weekly_count',
                        :conditions => "start_day between '#{start_of_week}' and '#{end_of_week}' and statistics_type_id = #{statistics_type.id} and agent_id >= 0",
                        :group => "agent_id")

          wlog("  - found result #{weekly_count.length} records")

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
            end
          end
          
        end
        
      end
    end

    wlog("[weekly-agents] finished ...")

    return bln_success

  end

  def monthly_statistics_agents(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true
    
    statistics_type = get_statistics_type( target_model, calcurate_type, by_agent )
    
    wlog("[monthly-Agents] stared ...")
    wlog("  - statistics_type => model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
    wlog("  - period from #{start_date} to #{end_date}")
    wlog("  - resource => #{DailyStatistics.class_name}")
    
    months = list_of_months(start_date, end_date)

    wlog("  - num_of_months => #{months.length} months ")
    
    unless months.empty?
      months.each do |month|

        start_month = month
        end_month = month.end_of_month + $start_day_of_month

        wlog("  - #{start_month.strftime("%b")}, #{start_month} - #{end_month}")

        if by_agent

          monthly_count = DailyStatistics.find(
                          :all,
                          :select => 'agent_id,sum(value) as monthly_count',
                          :conditions => "start_day between '#{start_month}' and '#{end_month}' and statistics_type_id = #{statistics_type.id}",
                          :group => "agent_id")
          
          wlog("  - found result #{monthly_count.length} records")
          
          unless monthly_count.blank?
            while (not monthly_count.empty?)
              item = monthly_count.pop
              update_or_create_data(MonthlyStatistics,{
                   :start_day => start_month,
                   :agent_id => item.agent_id,
                   :keyword_id => nil,
                   :value => item.monthly_count,
                   :statistics_type_id => statistics_type.id})
            end
          end

        end
      end
    end

    wlog("[monthly-Agents] finished ...")

    return bln_success

  end

  def statistics_agents(calc_mode='all',op={})
    
    wlog("[Statistics Agents] starting ...")
    
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

  # ================================================================= # KEYWORDS

  def daily_statistics_keywords(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true

    wlog("[daily-keywords] started ...")
    
    if by_agent
      
      $KEYWORD_TYPES.each do |kt|
        
        new_calcurate_type = "#{calcurate_type}:#{kt}"
        statistics_type = get_statistics_type( target_model, new_calcurate_type, by_agent )  
        
        wlog("  - statisticsType model=#{target_model}, type=#{new_calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
        wlog("  - period from #{start_date} to #{end_date}")          
        wlog("  - resource => #{ResultKeyword.class_name},#{EditKeyword.class_name}")
        wlog("  - num_of_days => #{(start_date..end_date).to_a.length} days ")
        
        keywords_id = Keyword.find(:all,:select => 'id',:conditions => {:keyword_type => kt, :deleted => false})
        
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
          
          wlog("  - found result #{daily_count.length} records")
          
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
      
      wlog("  - statisticsType model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("  - period from #{start_date} to #{end_date}")          
      wlog("  - resource => #{ResultKeyword.class_name},#{EditKeyword.class_name}")
      wlog("  - num_of_days => #{(start_date..end_date).to_a.length} days ")
      
      keywords_id = Keyword.find(:all,:select => 'id',:conditions => {:deleted => false})
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
            
        wlog("  - found result #{daily_count.length} records")   
        
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
    
    wlog("[daily-keywords] finished ...")

    return bln_success

  end

  def weekly_statistics_keywords(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true

    wlog("[weekly-keywords] started ...")
    
    weeks = list_of_weeks(start_date, end_date)
    
    if by_agent
      
      $KEYWORD_TYPES.each do |kt|
        
        new_calcurate_type = "#{calcurate_type}:#{kt}"
        statistics_type = get_statistics_type( target_model, new_calcurate_type, by_agent )
        
        wlog("  - statisticsType model=#{target_model}, type=#{new_calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
        wlog("  - period from #{start_date} to #{end_date}")          
        wlog("  - resource => #{DailyStatistics.class_name}")
        wlog("  - num_of_weeks => #{weeks.length} weeks ")
        
        unless weeks.empty?
          weeks.each do |week|
            
            start_week = week
            end_week = week + $DAYS_OF_THE_WEEK.length - 1            
            
            wlog("  - #{sprintf("%02d",start_week.cweek)}, #{start_week} - #{end_week}")
            
            weekly_count = DailyStatistics.find(
                        :all,
                        :select => 'agent_id,statistics_type_id,sum(value) as weekly_count',
                        :conditions => "start_day between '#{start_week}' and '#{end_week}' and (keyword_id = 0 OR keyword_id IS NULL) and statistics_type_id = #{statistics_type.id}",
                        :group => "agent_id,statistics_type_id")
                        
            wlog("  - found result #{weekly_count.length} records")   
            
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
      
      wlog("  - statisticsType model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("  - period from #{start_date} to #{end_date}")          
      wlog("  - resource => #{DailyStatistics.class_name}")      
      wlog("  - num_of_weeks => #{weeks.length} weeks ")
      
      unless weeks.empty?
        weeks.each do |week|
          
          start_week = week
          end_week = week + $DAYS_OF_THE_WEEK.length - 1       
        
          wlog("  - #{sprintf("%02d",start_week.cweek)}, #{start_week} - #{end_week}")
          
          weekly_count = DailyStatistics.find(
                        :all,
                        :select => 'keyword_id, sum(value) as weekly_count',
                        :conditions => "start_day between '#{start_week}' and '#{end_week}' and statistics_type_id = #{statistics_type.id}",
                        :group => 'keyword_id')

          wlog("  - found result #{weekly_count.length} records")  

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

    wlog("[Statistics WeeklyKeywords] finished ...")

    return bln_success
  
  end

  def monthly_statistics_keywords(target_model, calcurate_type, by_agent, start_date, end_date)

    bln_success = true

    wlog("[monthly-keywords] started ...")
    
    months = list_of_months(start_date, end_date)
    
    if by_agent
      
      $KEYWORD_TYPES.each do |kt|
        
        new_calcurate_type = "#{calcurate_type}:#{kt}"
        statistics_type = get_statistics_type( target_model, new_calcurate_type, by_agent )
        
        wlog("  - statisticsType model=#{target_model}, type=#{new_calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
        wlog("  - period from #{start_date} to #{end_date}")          
        wlog("  - resource => #{DailyStatistics.class_name}")
        
        unless months.empty?
          months.each do |month|
            
            start_month = month
            end_month = month.end_of_month + $start_day_of_month           
            
            wlog("  - #{start_month.strftime("%b")}, #{start_month} - #{end_month}")
            
            monthly_count = DailyStatistics.find(
                          :all,
                          :select => 'agent_id,statistics_type_id,sum(value) as monthly_count',
                          :conditions => "start_day between '#{start_month}' and '#{end_month}' and statistics_type_id = #{statistics_type.id}",
                          :group => "agent_id,statistics_type_id")
                        
            wlog("  - found result #{monthly_count.length} records")   
            
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
      
      wlog("  - statisticsType model=#{target_model}, type=#{calcurate_type}, by_agent=#{by_agent}, id=#{statistics_type.id}")
      wlog("  - period from #{start_date} to #{end_date}")          
      wlog("  - resource => #{DailyStatistics.class_name}")      
      
      unless months.empty?
        months.each do |month|
          
          start_month = month
          end_month = month.end_of_month + $start_day_of_month      
        
          wlog("  - #{start_month.strftime("%b")}, #{start_month} - #{end_month}")
          
          monthly_count = DailyStatistics.find(
                          :all,
                          :select => 'keyword_id,sum(value) as monthly_count',
                          :conditions => "start_day between '#{start_month.strftime("%Y-%m-%d")}' and '#{end_month.strftime("%Y-%m-%d")}' and statistics_type_id = #{statistics_type.id}",
                          :group => 'keyword_id')

          wlog("  - found result #{monthly_count.length} records")  

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
    
    wlog("[monthly-keywords] finished ...")

    return bln_success

  end

  def statistics_keywords(calc_mode='all',op={})

    wlog("[Statistics Keywords] started")

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
  
  # ================================================================= # MAIN

  def self.calc_statistics_voice_log(voice_log_id)

    voice_log = VoiceLog.find(:first,:conditons => {:id => voice_log_id})

    unless voice_log.nil?
      bookmark_count = CallBookmark.count(:id,:conditions => {:id => voice_log_id}).count.to_i

      select_sql = ""
      select_sql << " sum(result_keywords.id) as keyword_count, "
      select_sql << " sum(IF(keywords.keyword_type = 'n',1,0)) as ngword_count, "
      select_sql << " sum(IF(keywords.keyword_type = 'm',1,0)) as mustword_count "

      keyword_counts = Keyword.find(:first,
                                   :select => select_sql,
                                   :joins => :result_keywords,
                                   :conditions => "result_keywords.voice_log_id = #{voice_log_id}",
                                   :group => "keywords.id")

      keyword_count = 0
      ngword_count = 0
      mustword_count = 0
      unless keyword_counts.blank?
        keyword_count = keyword_counts.keyword_count.to_i
        ngword_count = keyword_counts.ngword_count.to_i
        mustword_count = keyword_counts.must_count.to_i
      end

      vc = VoiceLogCounter.find(:first,:conditions => {:voice_log_id => voice_log_id})
      if vc.nil?
         rs = VoiceLogCounter.new(vc.id,{
                :voice_log_id => voice_log_id, 
                :bookmark_count => bookmark_count,
                :ngword_count => 0,
                :mustword_count => 0,
                :keyword_count => 0}).save
      else
        rs = VoiceLogCounter.update(vc.id,{
                :bookmark_count => bookmark_count,
                :ngword_count => 0,
                :mustword_count => 0,
                :keyword_count => 0})
      end
    end
  end

  def calc_update_voice_log_counter()

    wlog("run reset_voice_log_counter")
    begin
      reset_voice_logs_counter
      wlog("run reset_voice_log_counter")
    rescue => e
      wlog("-error : #{e.message}")
    end
    
  end

  def clear_statistics_job

    wlog("Delete all jobs information")
    StatisticJob.delete_all()  

  end

  def run_statistics_job

    wlog("[Statistics Jobs] started ...")

    wlog("Get statistics jobs information")
    
    sjobs = StatisticJob.find(:all)

    acts = {}

    unless sjobs.empty?

      wlog("Checking statistics jobs information")
      sjobs.each do |j|
        if acts[j.act].nil?
           acts[j.act] = []
        end
        acts[j.act] << j.keyword_id
      end

      if not acts["delete"].nil?
        wlog("Update voice_log_counters for keywords: [#{acts["delete"].join(',')}]")
        calc_update_voice_log_counter()
      end

      if not acts["delete"].nil? and not acts["change_type"].nil?
        @c_daily_k = true
        ['daily','weekly','monthly'].each do |x|
          wlog("Update statistics keywords for #{x}")
          statistics_keywords(x,{:reset => true})
        end
        @c_daily_k = false
      end

      clear_statistics_job
      
    else
      wlog("No statistics jobs information")
    end

    wlog("[Statistics Jobs] finished ...")

  end

  def reset_voice_logs_counter

    # for count keywords

    # get keywords_id

    STDOUT.puts "Reset voice_logs_counter for keywords only"

    job_keywords = StatisticJob.find(:all)
    unless job_keywords.empty?

      keywords = []
      job_keywords.each do |k|
        keywords << k.keyword_id
      end
      job_keywords.clear

      STDOUT.puts "Keyword : #{keywords.join(',')}"
      keywords = keywords.uniq
      unless keywords.empty?

        end_date = Date.today
        start_date = VoiceLog.minimum(:start_time).to_date
        if start_date.nil?
          start_date = end_date
        else
          start_date = start_date.to_date
        end

        while start_date <= end_date

          STDOUT.puts "date: #{start_date}"

          sql = ""
          sql << " SELECT * FROM ( "
          sql << " (SELECT r.voice_log_id FROM result_keywords r WHERE keyword_id in (#{keywords.join(',')}) GROUP BY r.voice_log_id) "
          sql << " UNION "
          sql << " (SELECT r.voice_log_id FROM edit_keywords r WHERE keyword_id in (#{keywords.join(',')}) GROUP BY r.voice_log_id)) AS v "

          vls = VoiceLog.find_by_sql(sql)

          unless vls.empty?

            vls.each do |vl|

              voice_log_id = vl.voice_log_id

              #STDOUT.puts "voice_log: #{voice_log_id}"

              sql2 = " "
              sql2 << " SELECT r.voice_log_id, "
              sql2 << " COUNT(r.id) AS keyword_count, "
              sql2 << " COUNT(IF(k.keyword_type = 'n',1,0)) AS ngword_count, "
              sql2 << " COUNT(IF(k.keyword_type = 'm',1,0)) AS mustword_count FROM ("
              sql2 << " (SELECT r.id,r.voice_log_id,r.keyword_id FROM result_keywords r WHERE r.voice_log_id = #{voice_log_id} and r.edit_status IS NULL) "
              sql2 << " UNION "
              sql2 << " (SELECT r.id,r.voice_log_id,r.keyword_id FROM edit_keywords r WHERE r.voice_log_id = #{voice_log_id} and r.edit_status IS NULL) "
              sql2 << " ) r JOIN keywords k ON k.id = r.keyword_id WHERE k.deleted = false GROUP BY r.voice_log_id "

              result = VoiceLog.find_by_sql(sql2)
              unless result.empty?
                result = result.first

                vc = VoiceLogCounter.find(:first,:conditions => {:voice_log_id => voice_log_id})
                if vc.nil?
                  VoiceLogCounter.create({
                      :voice_log_id => voice_log_id,
                      :keyword_count => result.keyword_count.to_i,
                      :ngword_count => result.ngword_count.to_i,
                      :mustword_count => result.mustword_count.to_i,
                      :bookmark_count => 0
                    })
                else
                  VoiceLogCounter.update(vc.id,{
                      :keyword_count => result.keyword_count.to_i,
                      :ngword_count => result.ngword_count.to_i,
                      :mustword_count => result.mustword_count.to_i
                  })
                end
              end

            end

          end

          vl = []

          start_date = start_date + 1

        end

      end #end unless keywords

    end #end unless job_keywords

    STDOUT.puts "Delete all keywords in job"

    StatisticJob.delete_all

    STDOUT.puts "Reset voice_logs_counter finished"

  end
  
  ##
  ##========================================================================
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

    AmiLog.batch_log("Batch","StatisticsData/All",true,"StatisticsAll")
    
    initial_statistics_setting

    statistics_agents
    statistics_keywords
    
  end

  def statistics_main_repair

    wlog("")
    wlog("Run Statistics Repair")

    AmiLog.batch_log("Batch","StatisticsData/All",true,"StatisticsAll")
    
    initial_statistics_setting

    statistics_agents(nil,{:reset => true})
    statistics_keywords(nil,{:reset => true})
    
  end

  def statistics_main_agents

    AmiLog.batch_log("Batch","StatisticsData/Calls",true,"StatisticsAgentCalls")
    
    initial_statistics_setting
    statistics_agents
    
  end

  def statistics_main_keywords

    AmiLog.batch_log("Batch","StatisticsData/Keywords",true,"StatisticsKeywords")
    
    initial_statistics_setting
    statistics_keywords
    
  end

  def statistics_main_jobs  #keyword only

    AmiLog.batch_log("Batch","StatisticsData/Keywords",true,"StatisticsKeywordsJobs")
    
    initial_statistics_setting
    run_statistics_job
    
  end
  
end