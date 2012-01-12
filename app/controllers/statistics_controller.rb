
class StatisticsController < ApplicationController

  before_filter :login_required, :permission_require

  include AmiReport

  def index
    
    case params[:period]
    when /^daily/
      #
    when /^monthly/
      #
    when /^weekly/
      #
    else
      params[:period] = 'monthly'
    end
    @period = params[:period] 
    
    find_statistics_agent

  end

  def export
  
    find_statistics_agent

    col1 = []
    @display_first_labels.each_with_index { |c,i| col1 << [c,1,@display_cols_count[i]] }
    col2 = []
    @display_second_labels.each_with_index { |c,i| col2 << [c,1,1] }    
    col0 = []
    @display_second_labels.each_with_index { |c,i| col0 << [c,'int',5,1,1] }  
 
    @report[:cols] = {
        :multi => true,
        :cols => [
          ['No','no',3,1,1],
          ['Group','',7,1,1],
          ['Agent','',15,1,1],
          ['Total','int',4,1,1]
        ].concat(col0),
        :subs => [
          [
            ['No',2,1],
            ['Agent',2,1],
            ['Group',2,1],
            ['Total',2,1]
          ].concat(col1),
          [].concat(col2)
        ],
        :csv => ['No','Group','Agent','Total'].concat(@display_second_labels),
        :summary => [
          [['',1,1],['Total',1,2]]
        ]  
    }

    @report[:data] = []
    @agents.each_with_index do |agent,i|
      @report[:data] << [(i+1),agent['group'],agent['agent'],number_with_delimiter(agent['total'])].concat(agent['labels'])
    end

    @report[:summary] = [['','Total']]
    @grand_total.each { |g| @report[:summary][0] << number_with_delimiter(g) }
      
    @report[:fname] = "AgentReport"

    csvr = CsvReport.new
    csv_raw, filename = csvr.generate_report(@report)    
            
    send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)
    
   end

   def print

     find_statistics_agent

     col1 = []
     @display_first_labels.each_with_index { |c,i| col1 << [c,1,@display_cols_count[i]] }
     col2 = []
     @display_second_labels.each_with_index { |c,i| col2 << [c,1,1] }    
     col0 = []
     @display_second_labels.each_with_index { |c,i| col0 << [c,'int',3,1,1] }  
  
     @report[:cols] = {
         :multi => true,
         :cols => [
           ['No','no',3,1,1],
           ['Group','',7,1,1],
           ['Agent','',15,1,1],
           ['Total','int',5,1,1]
         ].concat(col0),
         :subs => [
           [
             ['No',2,1],
             ['Group',2,1],
             ['agent',2,1],
             ['Total',2,1]
           ].concat(col1),
           [].concat(col2)
         ],
         :summary => [
           [['',1,1],['Total',1,2]]
         ]  
     }

     @report[:data] = []
     @agents.each_with_index do |agent,i|
       @report[:data] << [(i+1),agent['group'],agent['agent'],number_with_delimiter(agent['total'])].concat(agent['labels'])
     end

     @report[:summary] = [['','Total']]
     @grand_total.each { |g| @report[:summary][0] << number_with_delimiter(g) }
       
     @report[:fname] = "AgentReport"
     
     pdfr = PdfReport.new
     pdf_raw, filename = pdfr.generate_report_one(@report)         
      
     send_data(pdf_raw, :file_type => Aohs::MIMETYPE_PDF, :filename => filename, :disposition => Aohs::DISPOSITION_PDF)
     
   end

   def find_statistics_agent
        
     @report = {}
     @report[:title_of] = Aohs::REPORT_HEADER_TITLE

     case params[:period]
     when /^daily/
       #
     when /^monthly/
       #
     when /^weekly/
       #
     else
       params[:period] = 'monthly'
     end
     @period = params[:period]
                  
     page = ((params[:page].to_i <= 1) ? 1 : params[:page].to_i )       
        
     number_of_cols = 0
     
     conditions = []
     ag_conditions = []
     select = []
     select2 = []
     
     from_date = params[:stdate]
     to_date = params[:eddate]
                
     @groups_id = []
     if params.has_key?(:group) and not params[:group].empty?
       @groups_id = params[:group].to_s
       @groups_id = @groups_id.strip.split(',').compact.uniq
       unless @groups_id.empty?
         agents = Agent.find(:all, :select => 'id', :conditions => { :group_id => @groups_id })
         unless agents.empty?
            tmp = (agents.map {|a| a.id }).join(',')
            conditions << "s.agent_id in (#{tmp})"
            ag_conditions << "u.id in (#{tmp})"
            tmp = nil
          else
            @groups_id = []
          end
        end
     end
      
     @agents_id = []
     if params.has_key?(:agent) and not params[:agent].empty?
       agents_id = params[:agent].to_s
       agents_id = agents_id.strip.split(",").compact.uniq    
       unless agents_id.empty?
          tmp = agents_id.join(',')
          conditions << "s.agent_id in (#{tmp})"
          ag_conditions << "u.id in (#{tmp})"
          @agents_id = agents_id
       else
          conditions << "s.agent_id = 0"
          ag_conditions << "u.id = 0"
       end
     end

     if @agents_id.empty?
        if permission_by_name('tree_filter')
          myagents = find_owner_agent
          unless myagents.blank?
            @agents_id = myagents.map { |a| a.id }
            tmp = @agents_id.join(',')
            conditions << "s.agent_id in (#{tmp})"
            ag_conditions << "u.id in (#{tmp})"
          else
            conditions << "s.agent_id = 0"
            ag_conditions << "u.id = 0"
          end
        else
          # all agents
          agents = Agent.find(:all,:select => 'id')
          unless agents.empty?
            @agents_id = (agents.map { |a| a.id })
            agents = nil
          end
        end        
      end
      
      @sub_type, statistics_type_id, rptitle = find_statistics_type_with_tabname(params[:sec],"agent-report")
      
      conditions << "s.statistics_type_id in (#{statistics_type_id})"

      statistics_model = nil
      dates = []
      case @period
      when 'daily'
        
        number_of_daily = AmiConfig.get('client.aohs_web.number_of_daily')
        statistics_model = DailyStatistics
        dates = find_statistics_date_rank(from_date, to_date, number_of_daily, 'daily')
        number_of_daily = dates.length

        @report[:title] = "Agents Daily Report (#{rptitle})"
        @report[:desc] = "Period from #{dates.first.strftime("%Y-%b-%d")} to #{dates.last.strftime("%Y-%b-%d")}"

        @display_first_labels = (dates.map{ |x| x.strftime('%b') }).uniq
        @display_second_labels = dates.map{ |x| x.strftime('%d').to_i }
        @display_cols_count = []
        @display_first_labels.each { |x| @display_cols_count << (dates.select {|y| x == y.strftime('%b')}).length }
        @display_columns = dates.map { |x| x.strftime('%Y-%m-%d')}
        map_cols = @display_columns

        @report[:period_rank_name] = dates.map { |x| x.strftime('%d/%m/%Y')}
        
        @st_date = dates.min
        @ed_date = dates.max
        
      when 'weekly'
        
        @nweeks = 12 * Aohs::WEEKS_PER_MONTH #AmiConfig.get('client.aohs_web.number_of_monthly').to_i * Aohs::WEEKS_PER_MONTH
        
        number_of_weekly = AmiConfig.get('client.aohs_web.number_of_weekly')
        begin_of_weekly = AmiConfig.get('client.aohs_web.beginning_of_week')
        statistics_model = WeeklyStatistics
        dates = find_statistics_date_rank(params[:stdate],params[:eddate],number_of_weekly,'weekly',DAYS_OF_THE_WEEK.index("#{begin_of_weekly}").to_i)

        @report[:title] = "Agents Weekly Report (#{rptitle})"
        @report[:desc] = "Period from #{dates.first.strftime("%Y-%b-%d")} to #{dates.last.strftime("%Y-%b-%d")}"

        @display_first_labels = (dates.map{ |x| x.strftime('%b') }).uniq
        start_week = DAYS_OF_THE_WEEK.index("#{begin_of_weekly}").to_i
        @display_second_labels = dates.map{ |x| "#{x.strftime('%d').to_i}-#{(x.end_of_week+start_week).strftime('%d').to_i}"  }
          
        @display_cols_count = []
        @display_first_labels.each { |x| @display_cols_count << (dates.select {|y| x == y.strftime('%b')}).length }
        @display_columns = dates.map { |x| x.strftime('%Y-%m-%d')}
        map_cols = @display_columns

        @st_date = dates.min
        @ed_date = dates.max.end_of_week
                        
      else
        
		@nmonths = 12 #AmiConfig.get('client.aohs_web.number_of_monthly').to_i
		
        number_of_monthly = AmiConfig.get('client.aohs_web.number_of_monthly')
        begin_of_month = AmiConfig.get('client.aohs_web.beginning_of_month')
        statistics_model =  MonthlyStatistics
        dates = find_statistics_date_rank(params[:stdate],params[:eddate],number_of_monthly,'monthly',begin_of_month - 1)

        @report[:title] = "Agents Monthly Report (#{rptitle})"
        @report[:desc] = "Period from #{dates.first.strftime("%b/%Y")} to #{dates.last.strftime("%b/%Y")}"
        
        @display_first_labels = (dates.map{ |x| x.strftime('%Y') }).uniq
        @display_second_labels = dates.map{ |x| x.strftime('%b') }
            
        @display_cols_count = []
        @display_first_labels.each { |x| @display_cols_count << (dates.select {|y| x == y.strftime('%Y')}).length }
        @display_columns = dates.map { |x| x.strftime('%Y-%m-%d')}
        map_cols = dates.map { |d| (Date.new(d.year, d.month, 5)).strftime('%Y-%m-%d') }

        @st_date = dates.min
        @ed_date = dates.max.end_of_month
        
      end

      order = "s.total"
      case params[:sort]
      when 'agent'
          order = 'u.agent_name'
      when 'total'
          order = "s.total"
      when 'group'
          order = "u.group_name"
      when /^(col-)/
          order = "s.c#{params[:sort].split('-').last}"
      end
      case params[:od]
        when 'desc'
          order = "#{order} desc"
        when 'asc'
          order = "#{order} asc"
        else
          order = "#{order} desc"
      end
      
      select << "s.agent_id"
      select << "sum(s.value) as total"
      select2 << "sum(s.value) as total"
      dates.each_with_index do |d,i|
          select << "sum(if(s.start_day = '#{d}',value,0)) as c#{i+1}"
          select2 << "sum(if(s.start_day = '#{d}',value,0)) as c#{i+1}"
      end
      
      conditions << "s.start_day >= '#{dates.min}'"
      conditions << "s.start_day <= '#{dates.max}'"
      
      u_display_name = "display_name"
      if AmiConfig.get('client.aohs_web.reportUserNameDisplay').to_i == 0
        u_display_name = "login"
      end
     
      sql1 = ""
      sql1 << "select u.id as agent_id2, u.group_id, u.display_name as agent_name, g.name as group_name "
      sql1 << "from users u left join groups g on u.group_id = g.id where u.type = 'Agent' "
      sql1 << "and #{ag_conditions.join(' and ')} " unless ag_conditions.empty?
      
      if params.has_key?(:agent) and not params[:agent].empty? and params[:agent].split(',').include?("0")
        sql1_1 = ""
        sql1_1 << " select 0 as agent_id2, 0, 'UnknownAgent' as agent_name, 'UnknownGroup' as group_name "
        
        sql1 = "select * from ((#{sql1}) union (#{sql1_1})) u "
      end
      
      sql2 = ""
      sql2 << "select #{select.join(',')} "
      sql2 << "from #{statistics_model.table_name} s "
      sql2 << "where #{conditions.join(" and ")} " unless conditions.empty?
      sql2 << "group by s.agent_id"
      
      sql3 = ""
      sql3 << "select * "
      sql3 << "from (#{sql1}) u left join (#{sql2}) s on u.agent_id2 = s.agent_id "
      sql3 << "order by #{order} "
 
      result = []
      if(params[:action] == "export" or params[:action] == "print")
         result = statistics_model.find_by_sql(sql3)
      else
         result = statistics_model.paginate_by_sql(sql3,:page => page, :per_page => $PER_PAGE)
      end

      @agents = []
      @agents2 = result
      
      unless result.empty?
          result.each do |x|
            agent = {}
            agent['id'] = x.agent_id2
            agent['group'] = x.group_name
            agent['agent'] = x.agent_name
            agent['total'] = x.total.to_i
            agent['labels'] = []
            dates.each_with_index do |d,i|
              begin
                  agent['labels'] << x["c#{i+1}".to_sym].to_i
              rescue
                  agent['labels'] << 0
              end
            end

            @agents << agent

          end
      end
      result.clear

      sql2 = ""
      sql2 << "select #{select2.join(',')} "
      sql2 << "from #{statistics_model.table_name} s "
      sql2 << "where #{conditions.join(" and ")} " unless conditions.empty?     
   
      result = statistics_model.find_by_sql(sql2)
      
      @grand_total = []
      unless result.empty?
        r = result.first
        unless r.nil?
          @grand_total << r.total.to_i
          dates.each_with_index do |d,i|
              begin
                  @grand_total << r["c#{i+1}".to_sym].to_i
              rescue
                  @grand_total << 0
              end
          end         
        end
      end
  
   end

    def agent
      
     find_agents_keyword
     render :layout => 'blank'
     
    end

    def fing_agent_call
      
    end
    
    def find_agents_keyword

      case params[:period]
      when /^daily/
        #
      when /^monthly/
        #
      when /^weekly/
        #
      else
        params[:period] = 'monthly'
      end
      period = params[:period] 
                   
      vc_conditions = []
      conditions = []

      agent_id = params[:agent_id]
      vc_conditions << "v.agent_id = #{agent_id.to_i}"
      @agent_detail = Agent.find(:first,:conditions => {:id => agent_id})
              
      sldate = params[:date]
      st_type = params[:type]

      order = ""
      case params[:sort]
        when 'keyword_group'
          order = "g.name"
        when 'keyword'
          order = "r.name"
        when 'type'
          order = "keyword_type"
        when 'calls'
          order = "calls_count"
        else
          order = "kcount"
      end
      case params[:od]
        when "asc"
          order = "#{order} asc"
        else
          order = "#{order} desc"
      end

      st_type, statistics_type_id, rptitle = find_statistics_type_with_tabname(st_type)

      case st_type
        when 'ng'
          conditions << "k.keyword_type = 'n'"
          @k_type = "NG words"
        when 'must'
          conditions << "k.keyword_type = 'm'"
          @k_type = "Must words"
        when 'action'
          conditions << "k.keyword_type = 'a'"
          @k_type = "Action words"
        else
          @k_type = "Keywords"
          conditions << "k.keyword_type in ('a','m','n')"
          #all 
      end
      
      if sldate.empty?
        #vc_conditions << "v.start_time <= '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}' "
        vc_conditions << "v.start_time between '#{params[:st]} 00:00:00' and '#{params[:ed]} 23:59:59' "
        st_date = params[:st]
        ed_date = params[:ed]
      else
        sldate = Date.parse(sldate)
        st_date = nil
        ed_date = nil
        case period
          when 'monthly'
            bm = AmiConfig.get('client.aohs_web.beginning_of_month')
            st_date = sldate.beginning_of_month + bm - 1
            ed_date = sldate.end_of_month + bm - 1
          when 'weekly'
            bw = begin_of_weekly = DAYS_OF_THE_WEEK.index(AmiConfig.get('client.aohs_web.beginning_of_week')).to_i
            st_date = sldate.beginning_of_week + bw
            ed_date = sldate.end_of_week + bw + 1
          else 'daily'
            st_date = sldate
            ed_date = sldate
        end
        if ed_date > Date.today
           ed_date = Time.now.strftime("%Y-%m-%d")
        else
           ed_date = Time.parse("#{ed_date} 23:59:59").strftime("%Y-%m-%d")
        end
        @label_col = "#{st_date} - #{ed_date}"
        vc_conditions << "v.start_time between '#{st_date} 00:00:00' and '#{ed_date} 23:59:59' "
      end
      
      @st_date = st_date
      @ed_date = ed_date
      
      vc_sql = "(select v.id from #{VoiceLogTemp.table_name} v where #{vc_conditions.join(' and ')})"
 
      sql0 = "select v.id as voice_log_id, count(r.id) as words_count, k.id as keyword_id, k.name, k.keyword_type, 1 as result "
      sql0 << "from #{vc_sql} v inner join (result_keywords r,keywords k) on v.id = r.voice_log_id and k.id = r.keyword_id "
      sql0 << "where k.deleted = false and r.edit_status is null "
      sql0 << "group by k.id, v.id "
           
      sql1 = "select v.id as voice_log_id, count(r.id) as words_count, k.id as keyword_id, k.name, k.keyword_type, 2 as result "
      sql1 << "from #{vc_sql} v inner join (edit_keywords r,keywords k) on v.id = r.voice_log_id and k.id = r.keyword_id "
      sql1 << "where k.deleted = false and r.edit_status in ('n','e') "
      sql1 << "group by k.id, v.id "
      
      sql2 = "select r.voice_log_id,sum(r.words_count) as words_count, r.keyword_id, r.name, r.keyword_type from ((#{sql0}) union (#{sql1})) r "
      sql2 << "group by r.voice_log_id, r.keyword_id "
      
      sql = "select r.keyword_id, r.name,g.name as keyword_group, sum(r.words_count) as kcount, r.keyword_type as keyword_type, count(r.voice_log_id) as calls_count from "
      sql << "(#{sql2}) r "
      sql << "join (keyword_group_maps kg, keyword_groups g) on r.keyword_id = kg.keyword_id and kg.keyword_group_id = g.id group by r.keyword_id "
      sql << "order by #{order}"
      
      if(params[:action] == "export_agent" or params[:action] == "print_agent")
        @result = VoiceLogTemp.find_by_sql(sql)
      else
        @result = VoiceLogTemp.paginate_by_sql(sql,:page => params[:page], :per_page => $PER_PAGE)
      end

      @result2 = []
      
      unless @result.empty?
        @result.each do |r|
          @result2 << {
            :id => r.keyword_id, 
            :name => r.name,
            :keyword_group => r.keyword_group, 
            :keyword_type => r.keyword_type, 
            :calls_count => r.calls_count.to_i, 
            :words_count => r.kcount.to_i 
          }
        end
      end

      sql = "select count(voice_log_id) as calls_count, sum(words_count) as words_count from (select r.voice_log_id, sum(r.words_count) as words_count from (#{sql2}) r group by r.voice_log_id) r "
            
      result = VoiceLogTemp.find_by_sql(sql).first
      calls_count = VoiceLogTemp.find_by_sql("select count(id) as calls_count from (#{vc_sql}) v").first.calls_count.to_i
      
      @grand_total = { :calls_count => result.calls_count, :words_count => result.words_count, :total_calls => calls_count}

   end


  def export_agent

      find_agents_keyword
      
      agent_name = @agent_detail.nil? ? "UnknownAgent" : @agent_detail.display_name
      group_name = @agent_detail.nil? ? "UnknownGroup" : @agent_detail.group.nil? ? "UnknownGroup" : @agent_detail.group.name
      
    @report = {}
    @report[:title_of] = Aohs::REPORT_HEADER_TITLE
    @report[:title] = "Agent Keyword Report (#{@k_type})"
    
    @report[:desc] = "Name: #{agent_name} Group:#{group_name} Period: #{@label_col}" 
        
    @report[:cols] = {
        :cols => [
          ['No','no',3,1,1],
          ['Keyword','',10,1,1],
          ['Keyword Pattern','',10,1,1],  
          ['Type','sym',7,1,1],
          ['Total Words','int',8,1,1],
          ['Total Calls','int',8,1,1]
        ],
        :summary => [
          [['',1,1],['Total',1,3]]
        ]
    }
    @report[:data] = []
    @result.each_with_index do |ri,i|
       @report[:data] << [(i+1),ri.keyword_group,ri.name,Keyword.display_keyword_type_name(ri.keyword_type),ri.kcount,ri.calls_count]
    end
    
    @report[:summary] = [['','','Total',number_with_delimiter(@grand_total[:words_count]),number_with_delimiter(@grand_total[:calls_count])]]

    @report[:fname] = "AgentKeywordReport"
    
     csvr = CsvReport.new
     csv_raw, filename = csvr.generate_report(@report)  
     
     send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)
    
  end

  def print_agent
  
     find_agents_keyword
     
     agent_name = @agent_detail.nil? ? "UnknownAgent" : @agent_detail.display_name
     group_name = @agent_detail.nil? ? "UnknownGroup" : @agent_detail.group.nil? ? "UnknownGroup" : @agent_detail.group.name
         
     @report = {}
     @report[:title_of] = Aohs::REPORT_HEADER_TITLE
     @report[:title] = "Agent Keyword Report (#{@k_type})"
     
     @report[:desc] = "Name: #{agent_name} Group:#{group_name} Period: #{@label_col}" 
         
    @report[:cols] = {
        :cols => [
          ['No','no',3,1,1],
          ['Keyword','',10,1,1],
          ['Keyword Pattern','',10,1,1],  
          ['Type','sym',7,1,1],
          ['Total Words','int',8,1,1],
          ['Total Calls','int',8,1,1]
        ],
        :summary => [
          [['',1,1],['Total',1,3]]
        ]
    }
    @report[:data] = []
    @result.each_with_index do |ri,i|
       @report[:data] << [(i+1),ri.keyword_group,ri.name,Keyword.display_keyword_type_name(ri.keyword_type),ri.kcount,ri.calls_count]
    end
    
    @report[:summary] = [['','Total',number_with_delimiter(@grand_total[:words_count]),number_with_delimiter(@grand_total[:calls_count])]]
      
    @report[:fname] = "AgentKeywordReport"

    pdfr = PdfReport.new
    pdf_raw, filename = pdfr.generate_report_one(@report)
           
    send_data(pdf_raw, :file_type => Aohs::MIMETYPE_PDF, :filename => filename, :disposition => Aohs::DISPOSITION_PDF)
    
   end
    
end
