class CustomersController < ApplicationController

  require 'cgi'

  before_filter :login_required
  before_filter :permission_require, :except => [:customers_name_list,:phone_list,:phone_update,:customer_update,:get_customer_id,:find_voice_cust]

  include AmiTimeline
  include AmiCallSearch
  
  def index

    @cd_color = Aohs::CALL_DIRECTION_COLORS
    @numbers_of_display = $CF.get('client.aohs_web.number_of_display_voice_logs').to_i
    
  end

  def find_voice_cust(sc={})

    vl_tbl_name = VoiceLogTemp.table_name

    skip_search = false
    conditions = []

    page = 1
    findby = ""

    customer_id = params[:cust_id].to_i  
    
    custs = []
    if customer_id > 0
      customer = Customer.where({:id => customer_id}).first
      if customer.nil?
        skip_search = true
      else
        custs << customer
      end
    elsif customer_id <= -1 and params.has_key?(:cust_name)
      cust_name = params[:cust_name].strip
      unless cust_name.empty?
        customers = Customer.where("customer_name like '%#{cust_name}%'").all
        if customers.empty?
          skip_search = true
        else
          custs = custs.concat(customers.to_a)
        end        
      end
    else
      # no set 
    end
    
    @customer_name = (params[:cust_name].blank? ? "UnknownCustomer" : params[:cust_name])
    
    phone_numbers = []
    cust_list = []
    if not custs.empty?
      custs_id = custs.map { |c| c.id }
      custs_numbers = CustomerNumber.select("number").where({ :customer_id => custs_id })
      unless custs_numbers.empty?
        phone_numbers = custs_numbers.map { |p| p.number } 
      end
      cust_list = custs_id
      if Aohs::MOD_CUSTOMER_LOOKUP
        # search by name
        conditions << "voice_log_customers.customer_id in (#{custs_id.join(",")})"
      end
    end

    if params.has_key?(:cust_phone) and not params[:cust_phone].empty?
      key_phone = (CGI::unescape(params[:cust_phone])).split(',').compact
      key_phone = key_phone.uniq
      phone_numbers = phone_numbers.concat(key_phone)
    end

    phone_numbers = phone_numbers.uniq
    unless phone_numbers.empty?
      ## %phone%
      phone_numbers = phone_numbers.map { |p| "%#{p}%" }
      pnumbers = phone_numbers.map { |p| "#{vl_tbl_name}.ani like '#{p}'"}
      pnumbers = pnumbers.concat(phone_numbers.map { |p| "#{vl_tbl_name}.dnis like '#{p}'"})
      
      # add search key for voice_log_customers
      pnumbers << "#{VoiceLogCustomer.table_name}.customer_id in (#{customer_id})" if customer_id > 0
      
      conditions << "(#{pnumbers.join(' or ')})"
    else
      skip_search = true
    end

    if params.has_key?(:no_phone) and not params[:no_phone].empty?
      key_phone = (CGI::unescape(params[:no_phone])).split(',').compact.uniq
      key_phone = key_phone.concat(key_phone.map { |p| "9#{p}" })
      unless key_phone.empty?
        key_phone = (key_phone.map { |p| "'#{p}'"}).join(",")
        conditions << "(#{vl_tbl_name}.ani not in (#{key_phone}) and #{vl_tbl_name}.dnis not in (#{key_phone})) "
      end
    end
    
    # car no
    if Aohs::MOD_CUST_CAR_ID
      if params.has_key?(:car_no) and not params[:car_no].empty?
          cn_tbl = VoiceLogCar.table_name
          car_keys = params[:car_no].to_s.strip.split(",").uniq
          car_keys = (car_keys.map { |c| "car_no like '%#{c.strip}%'" })
          cns = CarNumber.where(car_keys.join(" or ")).group("car_no").all
          STDOUT.puts cns.length
          unless cns.empty?
            #conditions << "(#{cn_tbl}.car_number_id in (#{ (cns.map { |c| c.id }).join(',') }) or #{cn_tbl}.car_number_id is null)"
            conditions << "(#{cn_tbl}.car_number_id in (#{ (cns.map { |c| c.id }).join(',') }))"
            skip_search = false
          else
            skip_search = true
            conditions << "#{cn_tbl}.car_number_id = 0"
          end
      end
    end
  
    if conditions.empty?
      skip_search = true
    else
      skip_search = false
    end

    conditions << retrive_datetime_condition(params[:dateCondition],params[:start_date],params[:start_time],params[:end_date],params[:end_time])
    
    # call direction
    call_directions = []
    if params.has_key?(:calld) and not params[:calld].empty?
      cd_ary = CGI::unescape(params[:calld]).split('')
      cd_ary.to_s.each_char do |c|
        call_directions << c
        call_directions.concat(['u','e']) if c == 'e'     
      end
      call_directions = [] if call_directions.uniq.sort == ['i','o','u','e'].sort 
      call_directions = call_directions.uniq.map { |c| "'#{c}'"}
    else
      skip_search = true
    end
    
    unless call_directions.empty?
      case call_directions.length
      when 1
        conditions << "#{vl_tbl_name}.call_direction = '#{call_directions.first.gsub('\'','')}'"
      else
        conditions << "#{vl_tbl_name}.call_direction in (#{call_directions.join(',')})"
      end    
    end

    # call duration
    conditions << retrive_duration_conditions(params[:stdur],params[:eddur])    

    #===========================================================================

    $PER_PAGE_CUST = params[:perpage].to_i 
    if $PER_PAGE_CUST <= 0
      $PER_PAGE_CUST =$CF.get('client.aohs_web.number_of_display_voice_logs').to_i  
    end

    page = params[:page].to_i if params.has_key?(:page) and not params[:page].empty? and params[:page].to_i > 0
    
    orders = []
    if sc[:timeline_enabled]
      orders = ['users.login asc',"#{vl_tbl_name}.start_time asc"]
    else
      orders = retrive_sort_columns(params[:sortby],params[:od])
    end

    start_row = $PER_PAGE_CUST* (page.to_i-1)
    records_count = 0
    offset = nil
    limit = nil

    unless sc[:show_all]
      offset = start_row
      limit = $PER_PAGE_CUST
    else
      offset = false
      limit = false
      max_show = $CF.get("client.aohs_web.number_of_max_calls_export").to_i
      if max_show > 0
        offset = 0
        limit = max_show
        page = 1
      end
    end

    find_summary = true
    if sc[:timeline_enabled]
      find_summary = false
    end

    voice_logs = []
    unless skip_search
      voice_logs,summary, page_info,agents = find_customer_calls({
                :select => [],
                :conditions => conditions,
                :order => orders,
                :offset => offset,
                :limit => limit,
                :page => page,
                :perpage => $PER_PAGE_CUST,
                :summary => find_summary,
                :ctrl => sc})
    end

    @voice_logs_ds = {:data => voice_logs, :page_info => page_info,:summary => summary }
    
  end

  def customer_voice_log
    
    find_voice_cust({:show_all => false, :timeline_enabled => false, :tag_enabled => true,:summary => true })
    
    render :json => @voice_logs_ds
    
  end

  def export

    show_all = ( (params[:type] =~ /true/) ? true : false )

    find_voice_cust({:show_all => show_all, :show_sub_call => true, :timeline_enabled => false, :tag_enabled => false })

     @display_columns = ["No","Date/Time","Duration","Caller Number","Dailed Number","Ext","Agent","Direction","NG word","Must word","Bookmark"]

    @report = {}
    @report[:title_of] = Aohs::REPORT_HEADER_TITLE
    @report[:title] = "Customer's Call List Report"
    
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
     @report[:fname] = "CustomerCallList" 
     csvr = CsvReport.new
     csv_raw, filename = csvr.generate_report(@report)    
  
     log("Export","VoiceLogs",true,filename)

     send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)
  
  end

  def print

    show_all = ( (params[:type] =~ /true/) ? true : false )

    find_voice_cust({:show_all => show_all, :show_sub_call => true, :timeline_enabled => false, :tag_enabled => false,:summary => true })

     @display_columns = ["No","Date/Time","Duration","Caller Number","Dailed Number","Ext","Agent","Direction","NG word","Must word","Bookmark"]

    @report = {}
    @report[:title_of] = Aohs::REPORT_HEADER_TITLE
    @report[:title] = "Customer's Call List Report"

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
    @report[:fname] = "CustomerCallList" 
    pdfr = PdfReport.new
    pdf_raw, filename = pdfr.generate_report_one(@report)
    
     log("Print","VoiceLogs",true,filename)

    send_data(pdf_raw, :file_type => Aohs::MIMETYPE_PDF, :filename => filename, :disposition => Aohs::DISPOSITION_PDF)

  end

end
