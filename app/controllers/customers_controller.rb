class CustomersController < ApplicationController

  require 'cgi'

  before_filter :login_required
  before_filter :permission_require, :except => [:customers_name_list,:phone_list,:phone_update,:customer_update,:get_customer_id,:find_voice_cust]

  include AmiTimeline
  include AmiCallSearch
  
  def index

    @cd_color = CALL_DIRECTION_COLORS
    @numbers_of_display = AmiConfig.get('client.aohs_web.number_of_display_voice_logs').to_i
    
  end

  def find_voice_cust(sc={})

    vl_tbl_name = VoiceLogTemp.table_name

    skip_search = false
    conditions = []

    page = 1
    findby = ""

    customer_id = params[:customer_id].to_i
    
    phone_numbers = []
    @customer_name = (params[:cust_name].blank? ? "UnknownCustomer" : params[:cust_name])
    if customer_id > 0
      customer = Customers.find(:first,:conditions => {:id => customer_id})
      unless customer.blank?
        @customer_name = customer.customer_name
        unless customer.customer_numbers.blank?
          customer.customer_numbers.each { |p| phone_numbers << p.number }
        end
      else
        skip_search = true
      end
    end

    if params.has_key?(:cust_phone) and not params[:cust_phone].empty?
      key_phone = (CGI::unescape(params[:cust_phone])).split(',').compact
      key_phone = key_phone.uniq
      phone_numbers = phone_numbers.concat(key_phone)
    end


    phone_numbers = phone_numbers.uniq
    unless phone_numbers.empty?
      ani_cond = phone_numbers.map { |p| "#{vl_tbl_name}.ani = '#{p}'"}
      dnis_cond = phone_numbers.map { |p| "#{vl_tbl_name}.dnis = '#{p}'"}
      conditions << "(#{ani_cond.concat(dnis_cond).join(' or ')})"
    else
      skip_search = true
    end

    conditions << retrive_datetime_condition(params[:dateCondition],params[:start_date],params[:start_time],params[:end_date],params[:end_time])

    # call direction
    call_directions = []
    if params.has_key?(:calld) and not params[:calld].empty?
      cd_ary = CGI::unescape(params[:calld]).split('')
      cd_ary.to_s.each_char do |c|
        call_directions << "'#{c}'"
        if c == 'e'
          call_directions << "'u'"
        end
      end
    else
      call_directions = ["'i'","'o'","'e'","'u'"]
    end

    case call_directions.length
    when 0
      # do nothing
    when 1
      conditions << "#{vl_tbl_name}.call_direction = '#{call_directions.first.gsub('\'','')}'"
    else
      conditions << "#{vl_tbl_name}.call_direction in (#{call_directions.join(',')})"
    end

    # call duration
    conditions << retrive_duration_conditions(params[:stdur],params[:eddur])    

    #===========================================================================

    $PER_PAGE_CUST = params[:perpage].to_i 
    if $PER_PAGE_CUST <= 0
      $PER_PAGE_CUST = AmiConfig.get('client.aohs_web.number_of_display_voice_logs').to_i  
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
      max_show = AmiConfig.get("client.aohs_web.number_of_max_calls_export").to_i
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
    
    find_voice_cust({:show_all => false, :timeline_enabled => false, :tag_enabled => true })
    
    render :json => @voice_logs_ds
    
  end

  def export

    show_all = ( (params[:type] =~ /true/) ? true : false )

    find_voice_cust({:show_all => show_all, :timeline_enabled => false, :tag_enabled => false })

     @display_columns = ["No","Date/Time","Duration","Caller Number","Dailed Number","Ext","Agent","Direction","NG word","Must word","Bookmark"]

    @report = {}
    @report[:title_of] = Aohs::REPORT_HEADER_TITLE
    @report[:title] = "Customer's call List Report"

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
     @report[:fname] = "CustomerCallList" 
     csvr = CsvReport.new
     csv_raw, filename = csvr.generate_report(@report)    
  
     log("Export","VoiceLogs",true,filename)

     send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)
  
  end

  def print

    show_all = ( (params[:type] =~ /true/) ? true : false )

    find_voice_cust({:show_all => show_all, :timeline_enabled => false, :tag_enabled => false })

     @display_columns = ["No","Date/Time","Duration","Caller Number","Dailed Number","Ext","Agent","Direction","NG word","Must word","Bookmark"]

    @report = {}
    @report[:title_of] = Aohs::REPORT_HEADER_TITLE
    @report[:title] = "Customer's call List Report"

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
    @report[:fname] = "CustomerCallList" 
    pdfr = PdfReport.new
    pdf_raw, filename = pdfr.generate_report_one(@report)
    
     log("Print","VoiceLogs",true,filename)

    send_data(pdf_raw, :file_type => Aohs::MIMETYPE_PDF, :filename => filename, :disposition => Aohs::DISPOSITION_PDF)

  end

end
