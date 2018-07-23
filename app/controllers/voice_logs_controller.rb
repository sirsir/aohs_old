require 'cgi' 
require "base64"

class VoiceLogsController < ApplicationController

  before_filter :login_required, :except => [:viewer]
  before_filter :permission_require, :except => [:voice_log_cols,:timeline_source,:manage_bookmark,:manage_keyword,:search_voice_log,:save_change_bookmark,:get_transfer_calls,:get_call_info,:file,:viewer]

  include AmiTimeline
  include AmiCallSearch

  def search_voice_logs(ctrl={})
		
		vl_tbl_name = VoiceLogTemp.table_name
		vlc_tbl 		= VoiceLogCounter.table_name
		conditions 	= []
		skip_search = false
		
		# agents conditions
		if params.has_key?(:keys) and not params[:keys].empty?
			
			params[:keys] = CGI::unescape(params[:keys])
			begin
				if not ctrl[:user_id].nil?
					set_current_user_for_call_search(ctrl[:user_id].to_i)
				else
					set_current_user_for_call_search(current_user.id)
				end
			rescue
				skip_search = true
			end
      
      added_agent_cond = false
			keys 		= CGI::unescape(params[:keys]).split("__")
			agents 	= []
			
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
			
			if params[:keys] == "agents=none__groups=none"
				# find all
				agents = find_owner_agents
				skip_search = true if not agents.nil? and agents.empty? 				
			else
				agents = nil if agents.empty?
			end

			if not agents.nil? and not agents.empty?
				agents = agents.uniq.sort
				# fixed agent_name and unknown agent
				if params.has_key?(:agent_id) and not params[:agent_id].empty?
					agent_id = params[:agent_id].strip.to_i
					agents = agents.include?(agent_id) ? [agent_id] : [] 
					skip_search = true if agents.empty?
				end
				conditions << "#{vl_tbl_name}.agent_id in (#{agents.join(',')})"
				added_agent_cond = true
			end
			
		else
			skip_search = true
		end

		# call date / time
		if params.has_key?(:sttime) and not params[:sttime].empty?
			params[:sttime] = CGI::unescape(params[:sttime])
		end
		if params.has_key?(:edtime) and not params[:edtime].empty?
			params[:edtime] = CGI::unescape(params[:edtime])
		end
		date_cond, stime, etime = retrive_datetime_condition(params[:periods],params[:stdate],params[:sttime],params[:eddate],params[:edtime])
    conditions << date_cond
    
		# extension
		if params.has_key?(:ext) and not params[:ext].empty?
			 ext_no = params[:ext].strip
			 exts_no = [ext_no]
			 ["5","6","7"].each do |ext_prefix| 
					exts_no << "#{ext_prefix}#{ext_no}"
			 end
			 conditions << "#{vl_tbl_name}.extension IN (#{(exts_no.map { |ex| "'#{ex}'"}).join(",")})"
		end
		
		#ani
		if params.has_key?(:caller) and not params[:caller].empty?
			caller_no = params[:caller].to_s.strip
			case true
			when caller_no.length <= 3
				conditions << "#{vl_tbl_name}.ani like '#{caller_no}%"
			when (not (caller_no =~ /^(8\*.+)/).nil?)
				conditions << "#{vl_tbl_name}.ani like '#{caller_no}%'"
			when caller_no.length <= 6
				conditions << "#{vl_tbl_name}.ani like '%#{caller_no}%'"
			else
				if caller_no[0,1] == "0"
					caller_no = caller_no[1..-1]
				end
				conditions << "#{vl_tbl_name}.ani like '%#{caller_no}%'"
			end
		end

		#dnis
		if params.has_key?(:dialed) and not params[:dialed].empty?
			dialed_no = params[:dialed].to_s.strip
			case true
			when dialed_no.length <= 3
				conditions << "#{vl_tbl_name}.dnis like '#{dialed_no}%"
			when (not (dialed_no =~ /^(8\*.+)/).nil?)
				conditions << "#{vl_tbl_name}.dnis like '#{dialed_no}%'"
			when dialed_no.length <= 6
				conditions << "#{vl_tbl_name}.dnis like '%#{dialed_no}%'"
			else
				if dialed_no[0,1] == "0"
					dialed_no = dialed_no[1..-1]
				end
				conditions << "#{vl_tbl_name}.dnis like '%#{dialed_no}%'"
			end
		end

		#agent id
		if added_agent_cond == false and params.has_key?(:agent_id) and not params[:agent_id].empty?
			agent_id = params[:agent_id].strip.to_i
			conditions << "#{vl_tbl_name}.agent_id = '#{agent_id}'"
		end
		
		# call direction
		call_directions = []
		if params.has_key?(:calld) and not params[:calld].empty?
			cd_ary = CGI::unescape(params[:calld]).split('')
			cd_ary.to_s.each_char do |c|
				call_directions << c
				#call_directions.concat(['u','e']) if c == 'e'     
			end
			call_directions = [] if call_directions.uniq.sort == ['i','o'].sort
			call_directions = call_directions.uniq.map { |c| "'#{c}'"}
			case call_directions.length
			when 0
			when 1
				conditions << "#{vl_tbl_name}.call_direction = '#{call_directions.first.gsub('\'','')}'"
			else
				conditions << "#{vl_tbl_name}.call_direction in (#{call_directions.join(',')})"
			end
		else
			skip_search = true
		end
  
		trfc_from = nil  
		trfc_to = nil
		if params.has_key?(:trfcfr) and not params[:trfcfr].empty?
			trfc_from = params[:trfcfr].to_i
			conditions << "#{vlc_tbl}.transfer_call_count >= #{trfc_from}"
		end
		if params.has_key?(:trfcto) and not params[:trfcto].empty?
			trfc_to = params[:trfcto].to_i
			conditions << "#{vlc_tbl}.transfer_call_count <= #{trfc_to}"
		end

		# call duration
		if params.has_key?(:stdur) and not params[:stdur].empty?
			params[:stdur] = CGI::unescape(params[:stdur])
		end
		if params.has_key?(:eddur) and not params[:eddur].empty?
			params[:eddur] = CGI::unescape(params[:eddur])
		end
		conditions << retrive_duration_conditions(params[:stdur],params[:eddur])


		if params.has_key?(:keyword) and not params[:keyword].empty?
			knames = CGI::unescape(params[:keyword]).split(" ")
			keywords = Keyword.select('id').where((knames.map { |k| "name like '%#{k}%'" }).join(" or ")).all
			if keywords.empty?
				skip_search = true
			else
				keywords = (keywords.map { |k| k.id }).join(',')
				conditions << "#{ResultKeyword.table_name}.keyword_id in (#{keywords})"
			end
		end
    
		$PER_PAGE_VC = params[:perpage].to_i 
		if $PER_PAGE_VC <= 0
			$PER_PAGE_VC = $CF.get('client.aohs_web.number_of_display_voice_logs').to_i  
		end  
		
		if params[:withtrnf] == "true" or params[:withtrnf].eql?("true")
			ctrl[:find_transfer] = true
		else
			ctrl[:find_transfer] = false
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
				max_show = $CF.get("client.aohs_web.number_of_max_calls_export").to_i
				if max_show > 0
					offset = 0
					limit = max_show
					page = 1
				end
			else
				offset = start_row
				limit = $PER_PAGE_VC
			end

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
			else
				voice_logs = []
			end

      voice_logs.each {|vl|        
        if (not vl.nil?) and (not vl[:path].nil?) and (not vl[:id].nil?)
          vl[:path] = Base64.encode64(vl[:path])
          vl[:path] = encrypt(vl[:path], vl[:id])
        end
      }

			@voice_logs_ds = {:data => voice_logs, :page_info => page_info,:summary => summary }
			
	end

  def encrypt(strIn,key)
    strOut = strIn.clone

    toInsert = []
    n=0
    while true
        nn=n*(n+1)/2
        if nn < strIn.length
          toInsert.push(nn)
          n = n+1
        else
            break
        end
    end

    key_arr = key.to_s.scan(/./)
    toInsert.each_with_index { |pos,idx|
      str2insert = if str2insert.nil? then "0" else key_arr[idx] end
      strOut.insert(pos,str2insert)
    }

    strOut
  end

	def index
    
			@cd_color = Aohs::CALL_DIRECTION_COLORS
			@username = current_user.login

			@numbers_of_display = $CF.get('client.aohs_web.number_of_display_voice_logs').to_i

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
      @conds[:keywords] = ((Keyword.select('name').where({:id => keywords})).map { |k| k.name }).join(" ")
    
      @conds[:agents_id] = []      
  	  if params.has_key?(:agent_id) and not params[:agent_id].empty?
  	    @conds[:agents_id] = params[:agent_id].to_s.split(",")
  	  end
  
  	  if params.has_key?(:group_id) and not params[:group_id].empty?
  	    group_id = params[:group_id]
  	    group = Group.select(:leader_id).where({ :id => group_id }).first
  	    unless group.nil?
          @conds[:agents_id] << group.leader_id.to_i if group.leader_id.to_i > 0 
  	    end
  	    agents_id = User.select('id').where({:group_id => group_id})
  	    @conds[:agents_id] = @conds[:agents_id].concat(agents_id.map { |u| u.id })
  	  end
        
      @conds[:agents_id] = @conds[:agents_id].join(',') unless @conds[:agents_id].nil?
      
    else
      # find all
      @conds = false
    end
    
    cd = params[:cd]
    if ['i','o','e','u'].include?(cd)
      @conds[:cd] = cd  
    end
    
    case params[:layout]
    when /^report/
      render :layout => 'voice_logs_report'
    end
    
  end

  def show

    voice_log_id = params[:id]

    get_keyword_pattern
    
    # if eq nil not check
    @my_agents = get_my_agent_id_list

    #begin
      @voice_log = VoiceLogTemp.where({:id => voice_log_id}).first
    #rescue => e
    #  log("Show", "VoiceLogs", false, e.message)
    #end

#    @voice_log = VoiceLogTemp.find(:first, :conditions => {:id => voice_log_id})

    render :layout => 'blank'

  end

  # new 20101216
  def get_keyword_pattern
    @keyword_pattern = Keyword.select('keywords.id, keywords.name, keywords.keyword_type as keyword_type, keyword_groups.id as group_id, keyword_groups.name as group_name').joins(:keyword_groups).order('name asc')
  end

  def search_voice_log

    search_voice_logs({:show_all => false, :timeline_enabled => false, :tag_enabled => true, :user_id => current_user.id })

    render :json => @voice_logs_ds

  end

  def export 

     show_all = ( (params[:type] =~ /true/) ? true : false )

     search_voice_logs({:show_all => show_all, :summary => true, :show_sub_call => true, :timeline_enabled => false, :tag_enabled => false, :user_id => current_user.id })

     @report = {}
     @report[:title_of] = Aohs::REPORT_HEADER_TITLE
     @report[:title] = "Agent's Call List Report"

     @report[:cols] = {}
     @report[:cols][:cols] = []
     @report[:cols][:cols] << ['No','no',3,1,1]
     @report[:cols][:cols] << ['Date/Time','date',10,1,1]
     @report[:cols][:cols] << ['Duration','int',7,1,1]
     @report[:cols][:cols] << ['Caller Number','',8,1,1]
     @report[:cols][:cols] << ['Dailed Number','',8,1,1]
     @report[:cols][:cols] << ['Ext','',4,1,1]
     @report[:cols][:cols] << ['Agent','',12,1,1]
     if Aohs::MOD_CUSTOMER_INFO
      @report[:cols][:cols] << ['Customer','',10,1,1]
      @report[:cols][:cols] << ['Car No','',5,1,1] if Aohs::MOD_CUST_CAR_ID
     end
     @report[:cols][:cols] << ['Direction','sym',4,1,1]
     if Aohs::MOD_KEYWORDS
      @report[:cols][:cols] << ['NG','int',5,1,1]
      @report[:cols][:cols] << ['Must','int',5,1,1] 
     end
     @report[:cols][:cols] << ['Bookmark','int',5,1,1] 
     
     @report[:data] = []
     @voice_logs_ds[:data].each_with_index do |vc,i|
       unless vc[:no].blank?
         if vc[:trfc] == true
           vc[:no] = "+ #{vc[:no]}"
         else
           if vc[:child] == true
            vc[:no] = ""  
           else
            vc[:no] = "   #{vc[:no]}" 
           end
         end
         p = [vc[:no],vc[:sdate],vc[:duration],vc[:ani],vc[:dnis],vc[:ext],vc[:agent]]
         if Aohs::MOD_CUSTOMER_INFO
          p << vc[:cust]
          p << vc[:car_no]
         end
         p << vc[:cd]
         if Aohs::MOD_KEYWORDS  
           p << vc[:ngc]
           p << vc[:mustc]
         end
         p << vc[:bookc]
         @report[:data] << p
       end
     end
     
     @report[:desc] = "Total Call: #{@voice_logs_ds[:summary][:c_in].to_i + @voice_logs_ds[:summary][:c_out].to_i}  In: #{@voice_logs_ds[:summary][:c_in]}  Out:#{@voice_logs_ds[:summary][:c_out]}  Other: #{@voice_logs_ds[:summary][:c_oth]}  Duration: #{@voice_logs_ds[:summary][:sum_dura]}"
     if Aohs::MOD_KEYWORDS  
       @report[:desc] << "  NG: #{@voice_logs_ds[:summary][:sum_ng]}"
       @report[:desc] << "  Must: #{@voice_logs_ds[:summary][:sum_mu]}"
     end
    
     @voice_logs_ds = nil
    
     @report[:fname] = "AgentCallList"
    
     csvr = CsvReport.new
     csv_raw, filename = csvr.generate_report(@report)    
     
     log("Export","VoiceLogs",true,filename)

     send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)

  end

  def print
    
     show_all = ((params[:type] =~ /true/) ? true : false )

     search_voice_logs({:show_all => show_all, :summary => true, :show_sub_call => true, :timeline_enabled => false, :tag_enabled => false, :user_id => current_user.id })

     @report = {}
     @report[:title_of] = Aohs::REPORT_HEADER_TITLE
     @report[:title] = "Agent's Call List Report"
      
     @report[:cols] = {}
     @report[:cols][:cols] = []
     @report[:cols][:cols] << ['No','no',3,1,1]
     @report[:cols][:cols] << ['Date/Time','date',10,1,1]
     @report[:cols][:cols] << ['Duration','int',6,1,1]
     @report[:cols][:cols] << ['Caller Number','',8,1,1]
     @report[:cols][:cols] << ['Dailed Number','',8,1,1]
     @report[:cols][:cols] << ['Ext','',4,1,1]
     @report[:cols][:cols] << ['Agent','',12,1,1]
     if Aohs::MOD_CUSTOMER_INFO
      @report[:cols][:cols] << ['Customer','',10,1,1]
      @report[:cols][:cols] << ['Car No','',9,1,1] if Aohs::MOD_CUST_CAR_ID
     end
     @report[:cols][:cols] << ['Direction','sym',5,1,1]
     if Aohs::MOD_KEYWORDS
      @report[:cols][:cols] << ['NG','int',5,1,1]
      @report[:cols][:cols] << ['Must','int',5,1,1] 
     end
     @report[:cols][:cols] << ['Bookmark','int',5,1,1] 
     
     @report[:data] = []
     @voice_logs_ds[:data].each_with_index do |vc,i|
       unless vc[:no].blank?
         if vc[:trfc] == true
           vc[:no] = "+ #{vc[:no]}"
         else
           if vc[:child] == true
            vc[:no] = ""  
           else
            vc[:no] = "   #{vc[:no]}" 
           end
         end
         p = [vc[:no],vc[:sdate],vc[:duration],vc[:ani],vc[:dnis],vc[:ext],vc[:agent]]
         if Aohs::MOD_CUSTOMER_INFO
          p << vc[:cust]
          p << report_car_breakline(vc[:car_no])
         end
         p << vc[:cd]
         if Aohs::MOD_KEYWORDS  
           p << vc[:ngc]
           p << vc[:mustc]
         end
         p << vc[:bookc]
         @report[:data] << p
       end
     end
     
     @report[:desc] = "Total Call: #{@voice_logs_ds[:summary][:c_in].to_i + @voice_logs_ds[:summary][:c_out].to_i}  In: #{@voice_logs_ds[:summary][:c_in]}  Out:#{@voice_logs_ds[:summary][:c_out]}  Other: #{@voice_logs_ds[:summary][:c_oth]}  Duration: #{@voice_logs_ds[:summary][:sum_dura]}"
     if Aohs::MOD_KEYWORDS  
       @report[:desc] << "  NG: #{@voice_logs_ds[:summary][:sum_ng]}"
       @report[:desc] << "  Must: #{@voice_logs_ds[:summary][:sum_mu]}"
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

   def get_transfer_calls
     
     voice_log_id = params[:voice_log_id].to_i
       
     transfer_voice_logs = find_transfer_calls(voice_log_id)

     transfer_voice_logs.each {|vl|        
        if (not vl.nil?) and (not vl[:path].nil?) and (not vl[:id].nil?)
          vl[:path] = Base64.encode64(vl[:path])
          vl[:path] = encrypt(vl[:path], vl[:id])
        end
      }
     
     render :json => transfer_voice_logs, :layout => false
     
   end

   def get_transfer_list
    
   end

   def get_call_info
     voice_log_id = params[:voice_log_id].to_i

     callinfo = []
     callinfos = CallInformation.where(:voice_log_id => voice_log_id)
     unless callinfos.nil?
       callinfos.each do |cnf|
         callinfo << {:st => cnf.start_msec, :en => cnf.end_msec, :evt=> cnf.event}
       end
     end

     render :json => callinfo
   end
   
   def file
    
      voice_log_id = params[:id]
      
      v = VoiceLog.where(:id => voice_log_id).first
      
      STDOUT.puts "GET File ID : #{v.id} url=#{v.voice_file_url}"
      
      unless v.nil?
        send_data v.voice_file_url
      else
        send_data "", :type => 'application/octet-stream'
      end
      
   end

	 def viewer
			
			@public_dir = "/var/www/html/tmpaudio"
			@pubilc_url = "http://192.168.1.88:80/tmpaudio"
			
			if params.has_key?(:upload) and params[:upload] == "yes"
        
        out_file = "false"
        
        if params.has_key?(:audio_file)
					
					tmp_dir = @public_dir          
					uploaded_file = params[:audio_file]
					tmp_file = File.join(@public_dir,uploaded_file.original_filename)
					File.open(tmp_file,'wb') do |file|
						file.write(uploaded_file.read)
					end
					
					out_file = uploaded_file.original_filename
					
        end
        
        redirect_to :action => 'viewer', :result => "success", :ofile => out_file
      
			else
		
				render :layout => 'blank'
      end
      
   end
	 
	 def download_file
			
			voice_log_id = params[:id]
			file_fmt = params[:type].to_s.downcase.to_sym
			
			voice_log = VoiceLog.select([:voice_file_url]).where({ :id => voice_log_id }).first
			tmp_file = AudioFileConverter.convert_from_url(voice_log.voice_file_url, file_fmt)
			
			send_data File.read(tmp_file), :filename => File.basename(tmp_file)
			#send_file tmp_file
			
   end
	 
end
