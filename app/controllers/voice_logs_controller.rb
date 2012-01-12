require 'cgi'

class VoiceLogsController < ApplicationController

   before_filter :login_required
   before_filter :permission_require, :except => [:voice_log_cols,:timeline_source,:manage_bookmark,:manage_keyword,:search_voice_log,:save_change_bookmark]

   include AmiTimeline
   include AmiCallSearch

   def search_voice_logs(ctrl={})
     
    vl_tbl_name = VoiceLogTemp.table_name

    conditions = []
    skip_search = false

    # === search conditions ===

    # agents conditions
    if params.has_key?(:keys) and not params[:keys].empty?

      begin
        if not ctrl[:user_id].nil?
          set_current_user_for_call_search(ctrl[:user_id].to_i)
        end
      rescue => e
        skip_search = true
      end

      keys = []
      keys = CGI::unescape(params[:keys]).split("__")
      agents = []
      keys.each do |key|
        k = key.split("=")
        case k[0]
          when /^(cate)/
            agents = find_agent_by_cate(k[1])
          when /^(groups)/
            if k[1] != "none"
              groups_id = k[1].split(',')
              agents.concat(find_agent_by_group(groups_id))
            end
          when /^(agents)/
            if k[1] != "none"
              agents.concat(find_agent_by_agents(k[1]))
            end
          when /^(agent)/
            agents = find_agent_by_agent(k[1])
          when /^(all)/
            agents = find_agent_by_group([])
        end
      end
      agents = nil if agents.empty?
      
      if agents.nil?
		if permission_by_name('tree_filter')
			conditions << "(agent_id is null or agent_id = 0)"
		end
      else
        if agents.empty?
          skip_search = true
        else
          conditions << "agent_id in (#{agents.join(',')})"
        end
      end

    else
      skip_search = true
    end

    # call date / time
    conditions << retrive_datetime_condition(params[:periods],params[:stdate],params[:sttime],params[:eddate],params[:edtime])

    # extension
    if params.has_key?(:ext) and not params[:ext].empty?
      conditions << "#{vl_tbl_name}.extension like '#{params[:ext]}%'"
    end

    #ani
    if params.has_key?(:caller) and not params[:caller].empty?
      conditions << "#{vl_tbl_name}.ani like '#{params[:caller].strip}%'"
    end

    #dnis
    if params.has_key?(:dialed) and not params[:dialed].empty?
      conditions << "#{vl_tbl_name}.dnis like '#{params[:dialed].strip}%'"
    end

    # call direction
    call_directions = []
    if params.has_key?(:calld) and not params[:calld].empty?
      cd_ary = CGI::unescape(params[:calld]).split('')
      cd_ary.to_s.each_char do |c|
        call_directions << "#{c}"
        if c == 'e'
          call_directions << "u"
          call_directions << "e"
        end
      end
	  call_directions = call_directions.uniq
	  if call_directions.include?('i') and call_directions.include?('o') and call_directions.include?('e')
		call_directions = []
	  end
	  call_directions = call_directions.map { |cd| "'#{cd}'" }
    else
      ##call_directions = ['i','o','e','u']
    end

    case call_directions.length
	when 0
	  ## find all direction
    when 1
      conditions << "#{vl_tbl_name}.call_direction = '#{call_directions.first.gsub('\'','')}'"
    else
      conditions << "#{vl_tbl_name}.call_direction in (#{call_directions.join(',')})"
    end

    # call duration
    conditions << retrive_duration_conditions(params[:stdur],params[:eddur])

    if params.has_key?(:keyword) and not params[:keyword].empty?
      
      # step 1 find keyword group without partial search
      # step 2 find keyword with partial search (if group not found)
      knames = CGI::unescape(params[:keyword]).split(" ")
      
      keywords 	= []
      #step 1 find keyword groups
      kgroups 	= KeywordGroup.find(:all,:select => "id", :conditions => (knames.map {|k| "name like '#{k.to_s}'"}).join(" or "))
      if kgroups.empty?
	 # step 2 find keyword group with keywords that matched
	 keyword_groups = KeywordGroup.find(:all,:joins => [:keywords],:conditions => (knames.map {|k| "keyword_groups.name like '#{k.to_s}'"}).join(" or ") + " AND keywords.deleted = false",:group => "id")
	 if keyword_groups.length == 1
	    keywords = Keyword.find(:all,:select => "keywords.id",:joins => [:keyword_group_maps], :conditions => ["keyword_group_maps.keyword_group_id in (?) and deleted = false",keyword_groups.map { |k| k.id }])
	 else
	    # step 3 find from keywords
	    keywords = Keyword.find(:all,:select => 'id', :conditions => "(#{(knames.map { |k| "name like '%#{k.to_s}%'" }).join(" or ")}) and deleted = false" )
	 end
      else 
	 keywords = Keyword.find(:all,:select => "keywords.id",:joins => [:keyword_group_maps], :conditions => ["keyword_group_maps.keyword_group_id in (?) and deleted = false",kgroups.map { |k| k.id }])
      end
      
      if keywords.empty?
        skip_search = true
      else
        keywords = (keywords.map { |k| k.id }).join(',')
        conditions << "#{ResultKeyword.table_name}.keyword_id in (#{keywords})"
      end
      
    end
      
    # ==========================================================================

    $PER_PAGE_VC = params[:perpage].to_i 
    if $PER_PAGE_VC <= 0
      $PER_PAGE_VC = AmiConfig.get('client.aohs_web.number_of_display_voice_logs').to_i  
    end  
      
    page = 1
    page = params[:page].to_i if params.has_key?(:page) and not params[:page].empty? and params[:page].to_i > 0

    orders = []
    if ctrl[:timeline_enabled]
      orders = ['users.login asc',"#{vl_tbl_name}.start_time asc"]
    else
      orders = retrive_sort_columns(params[:sortby],params[:od])
    end

    start_row = $PER_PAGE_VC*(page.to_i-1)

    if ctrl[:show_all] == true
      offset = 0
      limit = false
      page = false
      max_show = AmiConfig.get("client.aohs_web.number_of_max_calls_export").to_i
      if max_show > 0
        offset = 0
        limit = max_show
        page = 1
      end
    else
      offset = start_row
      limit = $PER_PAGE_VC
    end
    
    voice_logs = []
    unless skip_search
        voice_logs, summary, page_info, agents = find_agent_calls({
                :select => [],
                :conditions => conditions,
                :order => orders,
                :offset => offset,
                :limit => limit,
                :page => page,
                :perpage => $PER_PAGE_VC,
                :summary => true,
                :ctrl => ctrl })
    end

    @voice_logs_ds = {:data => voice_logs, :page_info => page_info,:summary => summary }

  end

  # ======= end seach voice log ======== #

  def index

    @cd_color = CALL_DIRECTION_COLORS
    @username = current_user.login

    @numbers_of_display = AmiConfig.get('client.aohs_web.number_of_display_voice_logs').to_i

    @conds = {}
    case params[:period]
    when /^(today)/
      tmp_date = Time.new.strftime("%Y-%m-%d")
      @conds[:st] = tmp_date
      @conds[:ed] = tmp_date
    when /^(yesterday)/
      tmp_date = (Time.new - (24*60*60)).strftime("%Y-%m-%d")
      @conds[:st] = tmp_date
      @conds[:ed] = tmp_date
    when /^(day_ago)/
      recent_days = params[:recents].to_i
      tmp_date = (Time.new - (recent_days*24*60*60)).strftime("%Y-%m-%d")
      @conds[:st] = tmp_date
      @conds[:ed] = tmp_date      
    when /^(daily)/,/^(weekly)/,/^(monthly)/
      @conds[:st] = params[:st]
      @conds[:ed] = params[:ed]
      
      keywords = params[:keyword_id].to_s.split(",")
      keywords = Keyword.find(:all,:select => 'name',:conditions => {:id => keywords})
      
      @conds[:keywords] = (keywords.map { |k| k.name }).join(" ")
      
      @conds[:agents_id] = []      
      if params.has_key?(:agent_id) and not params[:agent_id].empty?
	@conds[:agents_id] = params[:agent_id].to_s.split(",")
      end

      if params.has_key?(:group_id) and not params[:group_id].empty?
	group_id = params[:group_id]
	group = Group.find(:first,:select => :leader_id ,:conditions => { :id => group_id })
	unless group.nil?
	 @conds[:agents_id] << group.leader_id.to_i if group.leader_id.to_i > 0 
	end
	
	agents_id = User.find(:all,:select => 'id', :conditions => {:group_id => group_id})
	#agents_id = User.find(:all,:select => 'id', :conditions => {:group_id => group_id, :role_id => [0,Role.find(:first,:conditions => {:name => 'Agent'}).id]})
	@conds[:agents_id] = @conds[:agents_id].concat(agents_id.map { |u| u.id })
      end
        
      @conds[:agents_id] = @conds[:agents_id].join(',') unless @conds[:agents_id].nil?
      
    else
      # find all
      @conds = false
    end
    
    case params[:layout]
    when /^report/:
      render :layout => 'voice_logs_report'
    end
    
  end

#  def show
#
#    begin
#    @voice_log = VoiceLogTemp.find(params[:id])
#    @customer = VoiceLogCustomer.find(:first,:conditions =>{:voice_log_id => params[:id]})
#    keywords = Keyword.find(
#                        :all,
#                        :select => 'id,name,keyword_type',
#                        :conditions => {:deleted => false},
#                        :order => 'name asc')
#    @keywords_str_ary = []
#     unless keywords.blank?
#       keywords.each do |k|
#         kwg = KeywordGroup.find(:all,:select => "keyword_groups.name",:joins => :keyword_group_maps,
#               :conditions =>{:keyword_group_maps => {:keyword_id => k.id}})
#         unless kwg.empty?
#           kwg_str = kwg.map { |kgn| "#{kgn.name}" }.join(",")
#         else
#          kwg_str = "UnGroup"
#        end
#         @keywords_str_ary << "{name:'#{k.name}',ktype:'#{k.keyword_type}',kgroup:'#{kwg_str}'}"
#       end
#     end
#    rescue => e
#      log("Show","VoiceLogs",false,e.message)
#    end
#
#    render :layout => 'blank_old'
#
#  end

  # new 20101216
  def show

    voice_log_id = params[:id]

    get_keyword_pattern

    begin
      @voice_log = VoiceLogTemp.find(:first, :conditions => {:id => voice_log_id})
    rescue => e
      log("Show", "VoiceLogs", false, e.message)
    end

    render :layout => 'blank'

  end

  # new 20101216
  def get_keyword_pattern
    @keyword_pattern = Keyword.find(:all, :select => ['keywords.id as id, keywords.name as name, keywords.keyword_type as keyword_type, keyword_groups.id as group_id, keyword_groups.name as group_name'],:joins=> :keyword_groups, :order => 'name asc')
    
  end

  def search_voice_log

    search_voice_logs({:show_all => false, :timeline_enabled => false, :tag_enabled => true, :user_id => current_user.id })

    render :json => @voice_logs_ds

  end

  def export 

    show_all = ( (params[:type] =~ /true/) ? true : false )
    
    search_voice_logs({:show_all => show_all, :timeline_enabled => false, :tag_enabled => false, :user_id => current_user.id })

     @report = {}
     @report[:title_of] = Aohs::REPORT_HEADER_TITLE
     @report[:title] = "Agent's call List Report"

     @report[:cols] = {
         :cols => [
           ['No','no',3,1,1],
           ['Date/Time','date',10,1,1],
           ['Duration','int',7,1,1],
           ['Caller Number','',8,1,1],
           ['Dailed Number','',8,1,1],
           ['Ext','',4,1,1],
           ['Agent','',12,1,1], 
           ['Direction','sym',4,1,1], 
           ['NG','int',5,1,1],   
           ['Must','int',5,1,1],
           ['Bookmark','int',5,1,1]  
         ]
     }
     
     @report[:data] = []
     @voice_logs_ds[:data].each_with_index do |vc,i|
       unless vc[:no].blank?
         vc[:no] = (i+1)
         @report[:data] << [vc[:no],vc[:sdate],vc[:duration],vc[:ani],vc[:dnis],vc[:ext],vc[:agent],vc[:cd],vc[:ngc],vc[:mustc],vc[:bookc]]
       end
     end

     @voice_logs_ds = nil
    
     @report[:fname] = "AgentCallList"
    
     csvr = CsvReport.new
     csv_raw, filename = csvr.generate_report(@report)    
     
     log("Export","VoiceLogs",true,filename)

     send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)

  end

  def print
    
    show_all = ( (params[:type] =~ /true/) ? true : false )

    search_voice_logs({:show_all => show_all, :timeline_enabled => false, :tag_enabled => false, :user_id => current_user.id })

     @report = {}
     @report[:title_of] = Aohs::REPORT_HEADER_TITLE
     @report[:title] = "Agent's call List Report"

     @report[:cols] = {
         :cols => [
           ['No','no',3,1,1],
           ['Date/Time','date',10,1,1],
           ['Duration','int',7,1,1],
           ['Caller Number','',8,1,1],
           ['Dailed Number','',8,1,1],
           ['Ext','',4,1,1],
           ['Agent','',12,1,1], 
           ['Direction','sym',4,1,1], 
           ['NG','int',5,1,1],   
           ['Must','int',5,1,1],
           ['Bookmark','int',5,1,1]  
         ]
     }
     
     @report[:data] = []
     @voice_logs_ds[:data].each_with_index do |vc,i|
       unless vc[:no].blank?
         vc[:no] = (i+1)
         @report[:data] << [vc[:no],vc[:sdate],vc[:duration],vc[:ani],vc[:dnis],vc[:ext],vc[:agent],vc[:cd],vc[:ngc],vc[:mustc],vc[:bookc]]
       end
     end

     @voice_logs_ds = nil
    
     @report[:fname] = "AgentCallList"

     pdfr = PdfReport.new
     pdf_raw, filename = pdfr.generate_report_one(@report)
     
     log("Print", "VoiceLogs", true, filename)
     
     send_data(pdf_raw, :file_type => Aohs::MIMETYPE_PDF, :filename => filename, :disposition => Aohs::DISPOSITION_PDF)
           
   end

   def download

     voice_id = params[:voice_id].to_i

     v = VoiceLogTemp.find(:first,:conditions => {:id => voice_id})

     unless v.nil?
       log("Export","VoiceFile",true,"ID:#{params[:voice_id]}, File:#{File.basename(v.disposition)}")
       audio_url = audio_src_path(v.disposition)
       redirect_to audio_url
     else
       log("Export","VoiceFile",false,"ID:#{params[:voice_id]} not found")
       render :text => "No voicelogs"
     end

   end

end
