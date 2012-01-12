
class KeywordsController < ApplicationController

   before_filter :login_required, :except => [:keywords]
   before_filter :permission_require, :except => [:keywords,:update_group,:autocomplete_list,:result_keywords, :get_edit_keywords]

   include AmiReport
   require 'cgi'
   
   def index
     find_statistics_keyword
   end
 
   def find_statistics_keyword

     case params[:period]
     when /^d/
       @period = 'daily'
     when /^w/
       @period = 'weekly'
     else
       @period = 'monthly'
     end
          
    @report = {}
    @report[:title_of] = Aohs::REPORT_HEADER_TITLE
           
    @kwg = KeywordGroup.select("name").all
    
    number_of_cols = 0
    conditions = []
    kw_conditions = []
    select = []

    page = (params[:page].to_i >= 1) ? params[:page].to_i : 1 
    @page = page
    
    # type
    @sub_type, statistics_type_id, rptitle = find_statistics_type_with_tabname(params[:sec],"keyword_report")

    case @period
      when 'daily'
        number_of_daily = $CF.get('client.aohs_web.number_of_daily')
        statistics_model = DailyStatistics
        dates = find_statistics_date_rank(params[:stdate],params[:eddate],number_of_daily,'daily')
        number_of_daily = dates.length

        @report[:title] = "Keyword Daily Report (#{rptitle})"
        @rpname = @report[:name]
        @report[:desc] = "Period from #{dates.first.strftime("%d/%m/%Y")} to #{dates.last.strftime("%d/%m/%Y")}"

        @display_first_labels = (dates.map{ |x| x.strftime('%b') }).uniq
        @display_second_labels = dates.map{ |x| x.strftime('%d').to_i }
        @display_single_labels = dates.map{ |x| x.strftime('%d/%b')}
        @display_cols_count = []
        @display_first_labels.each { |x| @display_cols_count << (dates.select {|y| x == y.strftime('%b')}).length }
        @display_columns = dates.map { |x| x.strftime('%Y-%m-%d')}
        map_cols = @display_columns
      
      when 'weekly'
        
        filter_nmonths = $CF.get('client.aohs_web.filter.nof_recent_months').to_i
        number_of_monthly = $CF.get('client.aohs_web.number_of_monthly').to_i
        if filter_nmonths <= number_of_monthly
          filter_nmonths = number_of_monthly
        end
        ##filter_weeks = $CF.get('client.aohs_web.filter.nof_recent_months').to_i
        @nweeks = filter_nmonths * Aohs::WEEKS_PER_MONTH
      
        number_of_weekly = $CF.get('client.aohs_web.number_of_weekly')
        begin_of_weekly = $CF.get('client.aohs_web.beginning_of_week')
        statistics_model = WeeklyStatistics
        dates = find_statistics_date_rank(params[:stdate],params[:eddate],number_of_weekly,'weekly',Aohs::DAYS_OF_THE_WEEK.index("#{begin_of_weekly}").to_i)

        @report[:title] = "Keyword Weekly Report (#{rptitle})"
        @rpname = @report[:name]
        @report[:desc] = "Period from #{dates.first.strftime("%d/%m/%Y")} to #{dates.last.strftime("%d/%m/%Y")}"

        @display_first_labels = (dates.map{ |x| x.strftime('%b') }).uniq
        start_week = Aohs::DAYS_OF_THE_WEEK.index("#{begin_of_weekly}").to_i
        @display_second_labels = dates.map{ |x| "#{x.strftime('%d').to_i}-#{(x.end_of_week+start_week).strftime('%d').to_i}"  }
        @display_single_labels = dates.map{ |x| "#{x.strftime('%d/%b')} - #{(x.end_of_week+start_week).strftime('%d/%b')}"  }
        
        @display_cols_count = []
        @display_first_labels.each { |x| @display_cols_count << (dates.select {|y| x == y.strftime('%b')}).length }
        @display_columns = dates.map { |x| x.strftime('%Y-%m-%d')}
        map_cols = @display_columns
      
      else # 'M' and 'm' is default

        filter_nmonths = $CF.get('client.aohs_web.filter.nof_recent_months').to_i
        number_of_monthly = $CF.get('client.aohs_web.number_of_monthly')
        if filter_nmonths <= number_of_monthly
          filter_nmonths = number_of_monthly
        end
        @nmonths = filter_nmonths
        
        begin_of_month = $CF.get('client.aohs_web.beginning_of_month')
        statistics_model =  MonthlyStatistics
        dates = find_statistics_date_rank(params[:stdate],params[:eddate],number_of_monthly,'monthly',begin_of_month - 1)

        @report[:title] = "Keyword Monthly Report (#{rptitle})"
        @rpname = @report[:name]
        @report[:desc] = "Period from #{dates.first.strftime("%b/%Y")} to #{dates.last.strftime("%b/%Y")}"

        @display_first_labels = (dates.map{ |x| x.strftime('%Y') }).uniq
        @display_second_labels = dates.map{ |x| x.strftime('%b') }
        @display_single_labels = dates.map{ |x| x.strftime('%b/%Y') }
        @display_cols_count = []
        @display_first_labels.each { |x| @display_cols_count << (dates.select {|y| x == y.strftime('%Y')}).length }
        @display_columns = dates.map { |x| x.strftime('%Y-%m-%d')}
        map_cols = dates.map { |d| (Date.new(d.year, d.month, 5)).strftime('%Y-%m-%d') }
      
    end

    order = "s.total"
    case params[:sort]
    when 'name'
        order = (@sub_type == "group" ? 'k.keyword_group_name' : 'k.keyword_name')
    when 'type'
        order = 'k.keyword_type'
    when 'total'
        order = "sum(total)"
    when 'group'
        order = "k.keyword_group_name"
    when /^(col-)/
        order = "s.c#{params[:sort].split('-').last}"
    else
        order = "sum(total)"
    end
    
    case params[:od]
      when 'desc'
        order = "#{order} desc"
      when 'asc'
        order = "#{order} asc"
      else
        order = "#{order} desc"
    end

    if params.has_key?(:keywg_id) and not params[:keywg_id].empty? and params[:keywg_id].to_i > 0
      kw_conditions << "kg.id = '#{params[:keywg_id]}'"
	  kwg = KeywordGroup.where({:id => params[:keywg_id].to_i }).first
	  unless kwg.nil?
		params[:keywg] = kwg.name
	  end 
    else
      if params[:keywg_id] == "null"
        kw_conditions << "kg.id is null"
      end
    end
    if params.has_key?(:keywn) and not params[:keywn].empty?
      params[:keywn] = CGI::unescape(params[:keywn])
	  tmp_kw = CGI::unescape(params[:keywn].strip)
      kw_conditions << "k.name like '#{tmp_kw}%'" if tmp_kw.length > 0
    end
    if params.has_key?(:keywg) and not params[:keywg].empty?
      params[:keywg] = CGI::unescape(params[:keywg])
	  tmp_kg = CGI::unescape(params[:keywg].strip)
      kw_conditions << "kg.name like '#{tmp_kg}%'" if tmp_kg.length > 0
    end

    kw_conditions << "k.deleted = false"

    conditions << "s.start_day >= '#{dates.min}'"
    conditions << "s.start_day <= '#{dates.max}'"
    
    sql = ""
    sumsql = ""
    case @sub_type
      when "group"

        select2 = ['k.keyword_group_id','k.keyword_group_name','sum(s.total) as total']
        select3 = ['sum(s.total) as total']
        select << "s.keyword_id,k.keyword_group_id"
        select << "sum(s.value) as total"
        dates.each_with_index do |d,i|
            select << "sum(if(s.start_day = '#{d}',value,0)) as c#{i+1}"
            y = "sum(s.c#{i+1}) as c#{i+1}"
            select2 << y
            select3 << y
        end
        
        sql << " select #{select2.join(',')} from "
        sql << " (select k.id as keyword_id2,k.keyword_type, kg.id as keyword_group_id, kg.name as keyword_group_name "
        sql << " from keywords k left join (keyword_groups kg join keyword_group_maps km on kg.id = km.keyword_group_id) on k.id = km.keyword_id "
        sql << " where #{kw_conditions.join(" and ")} " unless kw_conditions.empty?
        sql << " group by k.id "
        sql << " ) k left join ( "
        sql << " select #{select.join(',')} "
        sql << " from #{statistics_model.table_name} s "
        sql << " where #{conditions.join(" and ")} " unless conditions.empty?
        sql << " group by s.keyword_id "
        sql << " ) s on s.keyword_id = k.keyword_id2 "
        sql << " group by k.keyword_group_id "
        sql << " order by #{order}"

        sumsql << " select #{select3.join(',')} from "
        sumsql << " (select k.id as keyword_id2, kg.id as keyword_group_id, kg.name as keyword_group_name "
        sumsql << " from keywords k left join (keyword_groups kg join keyword_group_maps km on kg.id = km.keyword_group_id) on k.id = km.keyword_id "
        sumsql << " where #{kw_conditions.join(" and ")} " unless kw_conditions.empty?
        sumsql << " group by k.id "
        sumsql << " ) k left join ( "
        sumsql << " select #{select.join(',')} "
        sumsql << " from #{statistics_model.table_name} s "
        sumsql << " where #{conditions.join(" and ")} " unless conditions.empty?
        sumsql << " group by s.keyword_id "
        sumsql << " ) s on s.keyword_id = k.keyword_id2 "

      else

        case @sub_type
          when 'ng'
            kw_conditions << "k.keyword_type = 'n'"
          when 'must'
            kw_conditions << "k.keyword_type = 'm'"
          when 'action'
            kw_conditions << "k.keyword_type = 'a'"
        end

        select2 = ["keyword_group_id,keyword_group_name,sum(s.total) as total"]
        select3 = ["keyword_id2,keyword_name,keyword_type,keyword_group_id,keyword_group_name,sum(s.total) as total"]
        select << "s.keyword_id"
        select << "sum(s.value) as total"
        dates.each_with_index do |d,i|
            select << "sum(if(s.start_day = '#{d}',value,0)) as c#{i+1}"
            select2 << "sum(s.c#{i+1}) as c#{i+1}"
            select3 << "sum(s.c#{i+1}) as c#{i+1}"
        end

        sql << " select #{select3.join(',')} from "
        sql << " (select k.id as keyword_id2, k.name as keyword_name,k.keyword_type, kg.id as keyword_group_id,kg.name as keyword_group_name "
        sql << " from keywords k join (keyword_groups kg join keyword_group_maps km on kg.id = km.keyword_group_id) on k.id = km.keyword_id "
        sql << " where #{kw_conditions.join(" and ")} " unless kw_conditions.empty?
        sql << " group by k.id "
        sql << " ) k left join ( "
        sql << " select #{select.join(',')} "
        sql << " from #{statistics_model.table_name} s "
        sql << " where #{conditions.join(" and ")} " unless conditions.empty?
        sql << " group by s.keyword_id "
        sql << " ) s on s.keyword_id = k.keyword_id2 "
        sql << " group by k.keyword_group_id "
        sql << " order by #{order}"

        sumsql << " select #{select2.join(',')} from "
        sumsql << " (select k.id as keyword_id2, k.name as keyword_name,k.keyword_type, kg.id as keyword_group_id,kg.name as keyword_group_name "
        sumsql << " from keywords k left join (keyword_groups kg join keyword_group_maps km on kg.id = km.keyword_group_id) on k.id = km.keyword_id "
        sumsql << " where #{kw_conditions.join(" and ")} " unless kw_conditions.empty?
        sumsql << " group by k.id "
        sumsql << " ) k left join ( "
        sumsql << " select #{select.join(',')} "
        sumsql << " from #{statistics_model.table_name} s "
        sumsql << " where #{conditions.join(" and ")} " unless conditions.empty?
        sumsql << " group by s.keyword_id "
        sumsql << " ) s on s.keyword_id = k.keyword_id2 "

    end
    
    @keywords = []
    if(params[:action] == "export" or params[:action] == "print")
       @keywords = statistics_model.find_by_sql(sql)
    else
       @keywords = statistics_model.paginate_by_sql(sql,:page => page, :per_page => $PER_PAGE)
       @keywords2 = @keywords
    end

    @keywords_total = []
    tmp_keywords_total = statistics_model.find_by_sql(sumsql)
    tmp_keywords_total.each do |x|
       total = x.total.blank? ? 0 : x.total
       @keywords_total << total
       dates.each_with_index do |d,i|
         @keywords_total << x["c#{i+1}".to_sym].to_i
       end
    end
    
    sql = nil
    sumsql = nil

    keyword_groups = KeywordGroup.select("keyword_group_maps.keyword_id,keyword_groups.name").joins(:keyword_group_maps).all if @sub_type != "group"

    keywords = []
    @keywords.each do |x|
      keyword = {}

      if @sub_type == "group"
        keyword['id'] = x.keyword_group_id
        keyword['name'] = x.keyword_group_name.blank? ? "UnGroup" : x.keyword_group_name       
      else
        kwg = []
        unless keyword_groups.empty?
          keyword_groups.each do |g|
            if x.keyword_id2.to_i == g.keyword_id.to_i
              kwg << g.name
            end
          end
		  kwg = kwg.uniq
        end
        keyword['id'] = x.keyword_group_id #x.keyword_id2
        keyword['name'] = x.keyword_name
        keyword['keyword_group'] = (kwg.empty? ? "-" : kwg.join(', '))
        keyword['type'] = x.keyword_type
        keyword['display_type'] = Keyword.display_keyword_type_name(x.keyword_type)
      end
      keyword['total'] = x.total.to_i
      keyword['labels'] = []
            dates.each_with_index do |d,i|
              begin
                  keyword['labels'] << x["c#{i+1}".to_sym].to_i
              rescue
                  keyword['labels'] << 0
              end
            end
      keywords << keyword
    end
    @keywords = keywords

    @span_cols = dates.length
     
   end
 
   def show

     @keyword = Keyword.find(params[:id])
     kwg = KeywordGroup.select("keyword_groups.name").joins(:keyword_group_maps).where({:keyword_group_maps => {:keyword_id => @keyword.id}})
     unless kwg.empty?
       @keyword_group = kwg.map { |kgn| "#{kgn.name}" }.join(",")
     else
       @keyword_group = "Undecided group"
     end
     
   end

   def new
     
     @keyword_group = KeywordGroup.all
     @keyword = Keyword.new

   end

   def edit

    begin
       
       @keyword_group = KeywordGroup.find(params[:id])
       @keyword = Keyword.joins([:keyword_group_maps]).where({:deleted => false, :keyword_group_maps => {:keyword_group_id => @keyword_group.id } })
       @keyword_group_map = KeywordGroupMap.where({:keyword_id => params[:id]})

    rescue => e
       
       log("Edit","Keyword",false,"#{params[:id]},#{e.message}")
       redirect_to :action => 'index'
       
     end

   end

   def create
     
     if not params[:keyword_group].empty?
       
       @keyword = Keyword.new(params[:keyword])
       @keyword.created_by = current_user.id
       @keyword.created_at = Time.new.strftime("%Y-%m-%d %H:%M:%S")   
       
       kwg = KeywordGroup.where({:name => params[:keyword_group]}).first
       if kwg.nil?
          kwg = KeywordGroup.create({:name => params[:keyword_group]})
          kwg.save   
       end
       
       if @keyword.save
         
          kwgm = KeywordGroupMap.new(:keyword_id => @keyword.id, :keyword_group_id => kwg.id)
          kwgm.save
          log("Add","Keyword",true,"id:#{@keyword.id}, name:#{@keyword.name}")
          
          redirect_to :action => 'edit', :id => kwg.id
          
       else
         
         log("Add","Keyword",false,@keyword.errors.full_messages)
         flash[:message] = @keyword.errors.full_messages
         
         render :action => 'new'    
                  
       end
       
     else
       flash[:message] = "Keyword name can not empty?"
       render :action => 'new'
     end

   end

   def update

#      @keyword = Keyword.find(params[:id])
# 
#      params[:keyword].merge!({:updated_by=> current_user.id,:updated_at=>Time.new.strftime("%Y-%m-%d %H:%M:%S")})
#        
#      if @keyword.update_attributes(params[:keyword])
#          
#        KeywordGroupMap.delete_all({:keyword_id => @keyword.id})
#         
#        kwg = KeywordGroup.find(:first,:conditions => {:name => params[:keyword_group]})
#        if kwg.nil?
#           kwg = KeywordGroup.create({:name => params[:keyword_group]})
#           kwg.save   
#        end
#        
#        kwgm = KeywordGroupMap.new(:keyword_id => @keyword.id, :keyword_group_id => kwg.id)
#        kwgm.save
#        
#        log("Update","Keyword",true,"id:#{params[:id]}")
#   
#        redirect_to :action => 'index'
#        
#      else
#        
#        log("Update","Keyword",false,"id:#{params[:id]}")
#        flash[:message] = 'Update keyword failed'
#
#        
#        
#      end
     
       redirect_to :action => 'edit', :id => params[:id]
         
       
   end

    def update_group
       
      errors = []
      
      keyword_group = params[:keyword_group]
      keyword_group_id = params[:id]  
      keyword_patterns = params[:patterns]
      keyword_type = params[:keyword_type]    
      
      keyword_ids = []
      new_keywords = []
      keyword_patterns.each_pair do |k,v| 
        if k.to_s =~ /(new)/
          new_keywords << v.to_s
        else
          keyword_ids << k.to_i
        end
      end
               
      kwg = KeywordGroupMap.where({:keyword_group_id => keyword_group_id})
        
      # update or delete old keywords
      STDOUT.puts ">>"+keyword_ids.join('==')  
      kwg.each do |k|
        if not Keyword.where({:id => k.keyword_id}).first == nil
          if keyword_ids.include?(k.keyword_id.to_i)
            # update
            STDOUT.puts "upd : #{k.keyword_id}"
            log("Update","Keyword",true,"id:#{k.keyword_id}, name:#{keyword_patterns[k.keyword_id.to_s]}")
            Keyword.update(k.keyword_id,{:name => keyword_patterns[k.keyword_id.to_s], :keyword_type => keyword_type })
          else
            # delete
            STDOUT.puts "del : #{k.keyword_id}"
            log("Delete","Keyword",true,"id:#{k.keyword_id}")
            Keyword.update(k.keyword_id,{:deleted => true,:deleted_at =>Time.new.strftime("%Y-%m-%d %H:%M:%S")})
          end
        else
            STDOUT.puts "lost : #{k.keyword_id}"
        end
      end
       
      # add new keyword
      
      new_keywords.each do |k|
        ok = Keyword.where({:name => k}).first
        if ok.nil?
          STDOUT.puts "new : #{k}"
          nk = Keyword.new({:name => k,:keyword_type => keyword_type})
          if nk.save
            kgm = KeywordGroupMap.new({:keyword_id => nk.id, :keyword_group_id => keyword_group_id})
            kgm.save  
            log("Add","Keyword",true,"id=#{nk.id},name=#{k}")
          else
            log("Add","Keyword",false,"name=#{k}")
            STDOUT.puts "failed : #{k}"
            errors << "keyword pattern cannot update may be duplicate or incorrect pattern"
          end
        end
      end
      
      # update keyword group
      STDOUT.puts "grp : #{keyword_group_id}"
      
      begin
        kg = KeywordGroup.where({:id => keyword_group_id}).first
        KeywordGroup.update(kg.id,{:name => keyword_group})  
        log("Update","KeywordGroup",true,"id=#{kg.id},name=#{kg.name}")
      rescue => e
        errors << e.message
        log("Update","KeywordGroup",false,"id=#{keyword_group_id}")
      end
      
      unless errors.empty?
        flash[:message] = errors
      end
      
      redirect_to :action => 'edit', :id => params[:id]
        
    end
  
   def delete #destroy

#     begin
#       
#       @keyword = Keyword.find(params[:id])
#
#       if @keyword.update_attributes(:deleted => true,:deleted_at =>Time.new.strftime("%Y-%m-%d %H:%M:%S"))
#         log("Delete","Keyword",true,"name:#{@keyword.name}")
#       else
#         log("Delete","Keyword",false,"name:#{@keyword.name}")
#         flash[:error] = 'Delete keyword failed.'
#       end
#     rescue => e
#       log("Delete","Keyword",false,"id:#{params[:id]}, #{e.message}")
#     end

     kg = KeywordGroup.where({:id => params[:id]}).first
     
     unless kg.nil?
                
       kgm = KeywordGroupMap.where({:keyword_group_id => kg.id})
         
       kgm.each do |k|
         Keyword.update(k.keyword_id,{:deleted => true,:deleted_at =>Time.new.strftime("%Y-%m-%d %H:%M:%S")})
       end
       
     end  
     
     redirect_to :action => 'index'

   end

   def export
     
     find_statistics_keyword

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
           ['Name','',20,1,1],
           ['Type','',4,1,1],
           ['Total','int',4,1,1]
         ].concat(col0),
         :subs => [
           [
             ['No',2,1],
             ['Name',2,1],
             ['Type',2,1],
             ['Total',2,1]
           ].concat(col1),
           [].concat(col2)
         ],
         :csv => ['No','Name','Type','Total'].concat(@display_single_labels),
         :summary => [
           [['',1,1],['Total',1,2]]
         ]  
     }     
     
     @report[:data] = []
     @keywords.each_with_index do |keyword,i|
       keyword['labels'] = keyword['labels'].map { |r| number_with_delimiter(r) }
       @report[:data] << [(i+1),keyword['name'],keyword['display_type'],number_with_delimiter(keyword['total'])].concat(keyword['labels'])
     end

     @report[:summary] = [['','Total']]
     @keywords_total.each { |g| @report[:summary][0] << number_with_delimiter(g) }

     @report[:fname] = "Keyword#{@period.capitalize}Report"

      csvr = CsvReport.new
      csv_raw, filename = csvr.generate_report(@report)    
              
      send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)

   end

   def print
     
     find_statistics_keyword

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
           ['Name','',10,1,1],
           ['Type','',4,1,1],
           ['Total','int',5,1,1]
         ].concat(col0),
         :subs => [
           [
             ['No',2,1],
             ['Name',2,1],
             ['Type',2,1],
             ['Total',2,1]
           ].concat(col1),
           [].concat(col2)
         ],
         :csv => ['No','Name','Type','Total'].concat(@display_second_labels),
         :summary => [
           [['',1,1],['Total',1,2]]
         ]  
     }     
     
     @report[:data] = []
     @keywords.each_with_index do |keyword,i|
       keyword['labels'] = keyword['labels'].map { |r| number_with_delimiter(r) }
       @report[:data] << [(i+1),keyword['name'],keyword['display_type'],number_with_delimiter(keyword['total'])].concat(keyword['labels'])
     end

     @report[:summary] = [['','Total']]
     @keywords_total.each { |g| @report[:summary][0] << number_with_delimiter(g) }

     @report[:fname] = "Keyword#{@period.capitalize}Report"

     pdfr = PdfReport.new
     pdf_raw, filename = pdfr.generate_report_one(@report)         
 
     send_data(pdf_raw, :file_type => Aohs::MIMETYPE_PDF, :filename => filename, :disposition => Aohs::DISPOSITION_PDF)
                
   end

   def keywords_agents     

     find_keyword_agents
     
     if params[:view] == 'agent'
       @agents = find_owner_agent
       unless @agents.blank?
         @agents = @agents.concat(@agents.map { |a| a.id })
         @agents << 0
       else
         @agents = nil
       end
     else
       @groups = find_owner_groups
     end

     render :layout => 'blank'
     
   end


   def find_keyword_agents

     @report = {}
     @report[:title_of] = Aohs::REPORT_HEADER_TITLE
     
     keywords = []
     conditions = []
     
     if params[:view] == 'group'
       group = 'group'
       @report[:title] = "Agent's Group Keyword Report"
     else
       group = 'agent'
       @report[:title] = "Agent Keyword Report"
     end

     case params[:type]
       when 'group'    
         if params[:id].to_i <= 0
           @keywordgroups = nil
           ktmp = Keyword.find(:all,
                              :select => "keywords.id as keyword_id",
                              :include => :keyword_group_maps,
                              :conditions => "keyword_group_maps.keyword_id is null",
                              :group => "keywords.id")
           unless ktmp.empty?
             keywords = ktmp.map {|g| g.id }
           end
         else

           @keywordgroups = KeywordGroup.find(:first,:conditions => {:id => params[:id]})
           ktmp = KeywordGroup.find(:all,
                                  :select => "keyword_group_maps.keyword_id",
                                  :joins => :keyword_group_maps,
                                  :conditions => {:id => params[:id]},
                                  :group => "keyword_group_maps.keyword_id")
           unless ktmp.empty?
             keywords = ktmp.map {|g| g.keyword_id }
           end
         end

       else
         
         kwg = KeywordGroupMap.find(:all,:conditions => {:keyword_group_id => params[:id]})
         keywords = kwg.map { |kg| kg.keyword_id }

     end

      order = "words_count"
      case params[:sort]
        when 'name'
          order = 'u.login'
        when 'group_name'
          order = 'group_name'
        when 'words'
          order = "words_count"
        when 'calls'
          order = "calls_count"
      end
      case params[:od]
        when 'desc'
          order = "#{order} desc"
        when 'asc'
          order = "#{order} asc"
        else
          order = "#{order} desc"
      end

     sl_date = params[:d]
     st_date = nil
     ed_date = nil
     show_all = false
     
     if sl_date.empty? or sl_date == 'all'
        st_date = params[:st].to_s + " 00:00:00"
        ed_date = params[:ed].to_s + " 23:59:59"
        @lable_col = "#{params[:st]} - #{params[:ed]}"
     else
       case params[:period]
         when /^m/
           st_date, ed_date = find_result_date_rank(sl_date,nil,'monthly')
           @lable_col = Time.parse(st_date).strftime("%b-%Y")
         when /^w/
           st_date, ed_date = find_result_date_rank(sl_date,nil,'weekly')
           @lable_col = "#{Time.parse(st_date).strftime("%Y-%m-%d")} to #{Time.parse(ed_date).strftime("%Y-%m-%d")}"
         else /^d/
           st_date, ed_date = find_result_date_rank(sl_date,nil,'daily')
           @lable_col = Time.parse(st_date).strftime("%Y-%m-%d")
       end       
     end
    
     @st_date = st_date.to_date
     @ed_date = ed_date.to_date
     
     @report[:desc] = "Period: #{@lable_col}"
     
     if params[:action] =~ /^(print)|^(export)/
       show_all = true
     else
       show_all = false
     end

     @result, @summary = find_keyword_report_with_agent({
             :show_all => show_all,
             :st_date => st_date,
             :ed_date => ed_date,
             :keywords => keywords,
             :group => group,
             :conditions => conditions,
             :order => order,
             :page => params[:page],
             :perpage => $PER_PAGE})

     @keywords = Keyword.where({:id => keywords}).all
     @report[:desc] << "  Keywords: #{(@keywords.map { |k| k.name }).join(', ')}"
       
     @unknow_title = ""
     if params[:view] == 'agent'
        @unknow_title = "UnknowAgent"
     else
        @unknow_title = "UnknowGroup" 
     end

   end
  
  def print_agent
  
     find_keyword_agents
 
     @report[:data] = []
     
     case params[:view]
     when /^agent/
      @report[:cols] = {
          :cols => [
            ['No','no',3,1,1],
            ['Agent','',10,1,1],
            ['Role','',10,1,1],
            ['Group','',10,1,1],
            ['Total Words','int',8,1,1],
            ['Total Calls','int',8,1,1]
          ],
          :summary => [
            [['',1,1],['Total',1,3]]
          ]
      }
       @result.each_with_index do |ri,i|
         title_name = ri.display_name.blank? ? @unknow_title : ri.display_name
         role_name = Role.find(:first,:conditions => {:id => ri.role_id.to_i }).name rescue "Agent"
         @report[:data] << [(i+1),title_name,role_name,ri.group_name,ri.words_count,ri.calls_count]       
       end 
       @report[:summary] = [['','Total',number_with_delimiter(@summary[:words_count]),number_with_delimiter(@summary[:calls_count])]]
     else
       @report[:cols] = {
           :cols => [
             ['No','no',3,1,1],
             ['Group','',7,1,1],
             ['Nuber of Agents','',15,1,1],
             ['Total Words','int',8,1,1],
             ['Total Calls','int',8,1,1]
           ],
           :summary => [
             [['',1,1],['Total',1,2]]
           ]             
       }
       @result.each_with_index do |ri,i| 
         title_name = ri.group_name.blank? ? @unknow_title : ri.group_name
         @report[:data] << [(i+1),title_name,ri.agents_count,ri.words_count,ri.calls_count]       
       end       
       @report[:summary] = [['','Total',number_with_delimiter(@summary[:words_count]),number_with_delimiter(@summary[:calls_count])]]  
     end

    @report[:fname] = "KeywordReport"
    
    pdfr = PdfReport.new
    pdf_raw, filename = pdfr.generate_report_one(@report)         
     
    send_data(pdf_raw, :file_type => Aohs::MIMETYPE_PDF, :filename => filename, :disposition => Aohs::DISPOSITION_PDF)
               
   end

  def export_agent
    
    find_keyword_agents
    @report[:data] = []
    
    case params[:view]
    when /^agent/
      @report[:cols] = {
          :cols => [
            ['No','no',3,1,1],
            ['Agent','',10,1,1],
            ['Role','',10,1,1],
            ['Group','',10,1,1],
            ['Total Words','int',8,1,1],
            ['Total Calls','int',8,1,1]
          ],
          :summary => [
            [['',1,1],['',1,1],['Total',1,3]]
          ]
      }
       @result.each_with_index do |ri,i|
         title_name = ri.display_name.blank? ? @unknow_title : ri.display_name
         role_name = Role.find(:first,:conditions => {:id => ri.role_id.to_i }).name rescue "Agent"
         @report[:data] << [(i+1),title_name,role_name,ri.group_name,ri.words_count,ri.calls_count]       
       end 
       @report[:summary] = [['','','Total',number_with_delimiter(@summary[:words_count]),number_with_delimiter(@summary[:calls_count])]]
    else
      @report[:cols] = {
          :cols => [
            ['No','no',3,1,1],
            ['Group','',7,1,1],
            ['Nuber of Agents','',15,1,1],
            ['Total Words','int',8,1,1],
            ['Total Calls','int',8,1,1]
          ],
          :summary => [
            [['',1,1],['Total',1,2]]
          ]             
      }
      @result.each_with_index do |ri,i| 
        title_name = ri.group_name.blank? ? @unknow_title : ri.group_name
        @report[:data] << [(i+1),title_name,ri.agents_count,ri.words_count,ri.calls_count]       
      end       
      @report[:summary] = [['','Total',number_with_delimiter(@summary[:words_count]),number_with_delimiter(@summary[:calls_count])]]  
    end

   @report[:fname] = "KeywordReport"
   
    csvr = CsvReport.new
    csv_raw, filename = csvr.generate_report(@report)    
            
    send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)
    
  end    


  def keywords

     if params.has_key?(:user) and not params[:user].empty?
       op = {:user => params[:user]}
     else
       op = {}
     end

     cm = []
     cm << " -*- coding: utf-8 -*-"
     cm << ""
     cm << " This keyword list is automatically generated from database at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
     cm << ""
     cm << " Original data:"
     cm << "\t#{request.url}"
     cm << " Format:"
     cm << "\t1: keywords.name"
     cm << "\t2: keywords.group"
     cm << "\t3: keywords.type"
     cm << "\t4: keywords.id"
     cm << ""

     keywords = Keyword.find_by_sql("select k.id,k.name,k.keyword_type,kg.name as group_name from keywords k join (keyword_group_maps km join keyword_groups kg on km.keyword_group_id = kg.id) on k.id = km.keyword_id where k.deleted = false ")

     bd = []
     keywords.each do |k|
       kname = k.name.strip
       ktype = k.keyword_type
       kid = k.id
       if k.group_name.nil?
        bd << "#{kname}\tUnknownGroup\t#{ktype}\t#{kid}"
       else
        bd << "#{kname}\t#{k.group_name}\t#{ktype}\t#{kid}"
       end
     end
     keywords.clear

     file = ""
     cm.each do |c|
       file << "# #{c}\r\n"
     end
     bd.each do |b|
       file << "#{b}\r\n"
     end

     log("Export","Keywords",true,"keywords.txt",op)

     send_data(file,:filename => 'keywords.txt')
     
   end

  def manage_keyword

    result = false

    begin

      unless params[:arrKeyword].empty?
        params[:arrKeyword].each do |kItem|
          kw = kItem.split(",");
          if kw[1].blank?
            break
          end
          
          STDOUT.puts 'result keyword is ' + kw[1].to_s
          keyword_name = kw[5]
          if Keyword.exists?({:name => keyword_name})
            STDOUT.puts 'keyword exists !!'
            kwn = Keyword.find(:first,:conditions =>{:name => keyword_name})
            if kwn.keyword_type.to_s != kw[4].to_s.downcase[0,1]
                kwn.update_attributes(:keyword_type => kw[4].to_s.downcase[0,1])
            end
            kwid = kwn.id
          else
            STDOUT.puts 'not exists make a new keyword.'
            if kw[5] != "#remove#"       
              kwn = Keyword.create({:name => keyword_name,:keyword_type => kw[4].to_s.downcase[0,1],:created_by => current_user.id})
              kwid = kwn.id
            end
          end

          if EditKeyword.exists?({:result_keyword_id => kw[1]})
             if kw[5].to_s != "#remove#"
                STDOUT.puts "result_keyword "+kw[1].to_s+" already exists in edit keyword update"
                edk = EditKeyword.find(:first,:conditions => {:result_keyword_id => kw[1]})
                edk.update_attributes(:voice_log_id => kw[0],
                            :keyword_id => kwid,
                            :start_msec => (kw[2].to_f * 1000),
                            :end_msec => (kw[3].to_f * 1000),
                            :user_id => (current_user.id),
                            :edit_status => 'e')
             else
                STDOUT.puts "result_keyword "+kw[1].to_s+" exists in edit_keyword and must delete it."
                edk = EditKeyword.find(:first,:conditions => {:result_keyword_id => kw[1]})
                edk.update_attributes(:edit_status => 'd')
             end
          else
           if ResultKeyword.exists?(kw[1])
              if kw[5].to_s != "#remove#"
                 STDOUT.puts kw[1].to_s + " not exists in edit keyword make new edit."
                 ResultKeyword.update(kw[1],:edit_status => 'e')
                 edk = EditKeyword.create({
                          :voice_log_id => kw[0],
                          :result_keyword_id => kw[1],
                          :keyword_id => kwid,
                          :start_msec => (kw[2].to_f * 1000),
                          :end_msec => (kw[3].to_f * 1000),
                          :user_id => current_user.id,
                          :edit_status => 'e'})
              else
                STDOUT.puts kw[1].to_s + " exists in result_keyword and must be delete."
                ResultKeyword.update(kw[1],:edit_status => 'd')
              end
           else
             if kw[5].to_s != "#remove#"
                STDOUT.puts "keyword is not exists in result and edit make it new record."
                rsk = ResultKeyword.create({
                        :voice_log_id => kw[0],
                        :keyword_id => kwid,
                        :edit_status => 'n'})
                edk = EditKeyword.create({
                        :keyword_id => kwid,
                        :voice_log_id => kw[0],
                        :user_id => current_user.id,
                        :start_msec => (kw[2].to_f * 1000),
                        :end_msec => (kw[3].to_f * 1000),
                        :edit_status => 'n',
                        :result_keyword_id => rsk.id})
             else
               STDOUT.puts "do not do anything junk array"
             end
           end
        end
       result = true
       log("Edit","CallKeywords",true,"id:#{kw[0]}")
       end
     end
     render :text => result ? 't' : 'f'
  rescue => ex
    log("Edit","CallKeywords",false,"#{ex.message}")
    STDERR.puts ex.backtrace
    render :text => 'f'
  end
  end

  def autocomplete_list 
    
    name = params[:q]
    limit = params[:limit].to_i
    
    conditions = []
    unless name.blank?
      conditions = "name like '%#{name}%'"
    end
          
    keywords = Keyword.find(:all,
        :select => 'name',
        :conditions => conditions,
        :order => 'name asc',
        :limit => limit)
    
    render :text => (keywords.map { |k| k.name }).join("\r\n")
    
  end

  def result_keywords 
  
    result = []
    case params[:word]
    when /^M/
      wtype = "m"
    when /^N/
      wtype = "n"
    else
      wtype = nil
    end  
    
    voice_id = params[:voice_id].to_i
    if voice_id > 0
      rs = ResultKeyword.find(:all,
        :select => 'result_keywords.id, result_keywords.keyword_id,keywords.name,count(result_keywords.id) as keyword_count',
        :joins => [:keyword],
        :conditions => {:voice_log_id => voice_id,:keywords => {:keyword_type => wtype}},
        :order => 'name',
        :group => 'keyword_id')
      unless rs.empty?
        rs.each do |r|
          result << "#{r.name} (#{r.keyword_count})"
        end
      end
    end 
    
    if result.empty?
      render :text => "No keyword."
    else
      render :text => result.join("<br/>");
    end  
    
  end

  # for 'voice_logs/shows/....' page
  def save_change_keyword

    voice_log_id = params[:voice_log_id]
    result_keywords = params[:result_keywords] || []
    result_keywords_del = params[:result_del] || []
    edit_keywords = params[:edit_keywords] || []
    edit_keywords_del = params[:edit_del] || []

    # Begin : ResultKeywords :: for delete ::
    unless result_keywords_del.empty?
      result_keywords_del.each do |rsk_id|
        ResultKeyword.update(rsk_id, {:edit_status => 'd'})
        STDOUT.puts "<result_keyword> result_keyword id :: #{rsk_id} :: change edit_status to 'd'"
      end
    end
    # End : ResultKeywords :: for delete ::

    # Begin : ResultKeywords :: for update ::
    unless result_keywords.empty?
      result_keywords.each do |rs|
        result_info = rs.split(",")

        start_time = (result_info[0].to_f)*1000
        end_time = (result_info[1].to_f)*1000
        keyword_id = result_info[2]
        id = result_info[3]

        db_result = ResultKeyword.find(:first, :conditions => {:id => id})
        if not db_result.nil?
          if db_result.start_msec.to_f == start_time and
             db_result.end_msec.to_f == end_time and
             db_result.keyword_id.to_i == keyword_id.to_i

            STDOUT.puts "<result_keyword>  not update result_keyword id :: '#{id}'"
          else
            ResultKeyword.update(id,{:edit_status => 'd'})
            STDOUT.puts "<result_keyword>  result_keyword id :: #{id} :: change edit_status to 'd'"

            new_edit = EditKeyword.new(:keyword_id => keyword_id,
                                       :voice_log_id => voice_log_id,
                                       :start_msec => start_time,
                                       :end_msec => end_time,
                                       :result_keyword_id => id,
                                       :user_id => current_user.id,
                                       :edit_status => 'e')
            if new_edit.save
              STDOUT.puts "<result_keyword> --> create new edit_keyword < start_msec: #{start_time}, end_msec: #{end_time}, result_keyword_id: #{id}, keyword_id: #{keyword_id}, voice_lod_id: #{voice_log_id} > by #{current_user.id}"
            else
              STDOUT.puts "<result_keyword> --> can't create new edit_keyword"
            end

          end
        end
      end
    end
    # End : ResultKeywords :: for update ::

    # Begin : EditKeywords :: for delete ::
    unless edit_keywords_del.empty?
      edit_keywords_del.each do |edk_id|
        EditKeyword.update(edk_id,{:edit_status => 'd'})
        STDOUT.puts "<edit_keyword> edit_keyword id :: #{edk_id} :: change edit_status to 'd'"
      end
    end
    # End : EditKeywords :: for delete ::

    # Begin : EditKeywords :: for update ::
    unless edit_keywords.empty?
      edit_keywords.each do |edk|
        edit_info = edk.split(",")

        start_time = (edit_info[0].to_f)*1000
        end_time = (edit_info[1].to_f)*1000
        keyword_id = edit_info[2]
        id = edit_info[3]

        if id != "-1"
          db_edit = EditKeyword.where(:id => id).first
          if not db_edit.nil?
            if db_edit.start_msec.to_f == start_time and
               db_edit.end_msec.to_f == end_time and
               db_edit.keyword_id.to_i == keyword_id.to_i

              STDOUT.puts "<edit_keyword>  not update result_keyword id :: '#{id}'"
            else
              EditKeyword.update(id, {:keyword_id => keyword_id, :start_msec => start_time, :end_msec => end_time, :edit_status => 'e'})
              STDOUT.puts "<edit_keyword>  update edit_keyword :: '#{id}'"
            end
          end
        else
          new_edit = EditKeyword.new(:keyword_id => keyword_id,
                                     :voice_log_id => voice_log_id,
                                     :start_msec => start_time,
                                     :end_msec => end_time,
                                     :result_keyword_id => nil,
                                     :user_id => current_user.id,
                                     :edit_status => 'n')

          if new_edit.save
            STDOUT.puts "<edit_keyword> --> create new edit_keyword < start_msec: #{start_time}, end_msec: #{end_time}, result_keyword_id: null, keyword_id: #{keyword_id}, voice_lod_id: #{voice_log_id} >"
          else
            STDOUT.puts "<edit_keyword> --> can't create new edit_keyword"
          end
        end
      end
    end
    # End : Edit Keywords :: for update ::

    render :text => "Update keyword complete."
  end

  def get_edit_keywords

    voice_log_id = params[:voice_log_id]
    db_name = params[:db_name]
    kw_info = []

    sql = "";
    sql += "select ";
    sql += " r.id as id, r.voice_log_id as voice_log_id, (r.start_msec/1000) as st_sec, (r.end_msec/1000) as en_sec, ";
    sql += " r.keyword_id as keyword_id, k.keyword_type as keyword_type, k.name as keyword_name, ";
    sql += " kgm.keyword_group_id as keyword_group_id, kg.name as keyword_group_name, r.edit_status as edit_status ";
    sql += "from "+db_name+" r ";
    sql += "left join keywords k on r.keyword_id = k.id ";
    sql += "left join keyword_group_maps kgm on kgm.keyword_id = r.keyword_id ";
    sql += "left join keyword_groups kg on kgm.keyword_group_id = kg.id ";
    sql += "where r.voice_log_id = #{voice_log_id} ";
    sql += (db_name == 'edit_keywords' ? "and r.edit_status != 'd' " : "and r.edit_status is null ");
    sql += "order by start_msec ";

    if db_name == 'edit_keywords'
      kw = EditKeyword.find_by_sql(sql)
    else
      kw = ResultKeyword.find_by_sql(sql)
    end

    unless kw.empty?
      kw.each do |k|
        kw_info << {:st_sec => k.st_sec, :en_sec => k.en_sec, :kw_name => k.keyword_name, :kw_type => k.keyword_type,
                    :kw_id => k.keyword_id, :kw_grp_id => k.keyword_group_id, :kw_grp_name => k.keyword_group_name,
                    :edit_sts => k.edit_status, :id => k.id, :from => db_name
                    }
      end
    end

    render :json => kw_info
  end

end