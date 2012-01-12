class FavoritesController < ApplicationController

  require 'cgi'
  
  before_filter :login_required
  before_filter :permission_require, :except => [:get_voice_log_list, :manage_tag]

  include AmiCallSearch

  def index
    
    @tag_groups = TagGroup.find(:all,:order => 'name')
    
    @cd_color = CALL_DIRECTION_COLORS
    @rows_per_page = $PER_PAGE
    @favarite = Tags.find(:all,:order => 'name')
    @numbers_of_display = AmiConfig.get('client.aohs_web.number_of_display_voice_logs').to_i
        
    get_tag_list
    
  end


  def get_tag_list

    @arr_charactor = {}
    @arr_non_used =  []
    
    key_string = "กขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮabcdefghijklmnopqrstuvwxyz0123456789"
    sara = "โไใเแ"

    nonused_tags = Taggings.find(:all,:group=>:tag_id)
    nonused_tags.each do |nut|
      @arr_non_used << nut.tag_id
    end

    condition = nil
    unless @arr_non_used.empty?
      condition = "name is not null and id in(" +@arr_non_used.join(",")+")"
    end

    data_tags = Tags.find(:all,:order=>'name',:conditions=>condition)

    unless data_tags.empty?
      data_tags.each do |val|
        key_string.each_char do |keys|
          if val.name.downcase =~ /^(#{keys})(.+)/ or val.name.downcase =~ /^([#{sara}]+)(#{keys})(.+)/
            if @arr_charactor["#{keys.upcase}"].nil?
              @arr_charactor["#{keys.upcase}"]= [val.name]
            else
              @arr_charactor["#{keys.upcase}"]<< val.name
            end
            break
          end
        end
      end
    end

  end

  def find_call_tag(ctrl={})

    vl_tbl_name = VoiceLogTemp.table_name
    
    page = 1
    page = params[:page].to_i if params.has_key?(:page) and not params[:page].empty? and params[:page].to_i > 0

    tags_key = CGI::unescape(params[:tag])
    group_id_key = params[:group_id]
    tag_id_key = params[:tag_id]
    
    orders = []
    orders = retrive_sort_columns(params[:sortby],params[:od])      

    # limit
    
    $PER_PAGE = params[:perpage].to_i 
    if $PER_PAGE <= 0
      $PER_PAGE = AmiConfig.get('client.aohs_web.number_of_display_voice_logs').to_i  
    end  
    
    start_row = $PER_PAGE * (page.to_i-1)

    if ctrl[:show_all] == true
      offset = 0
      limit = false
      page = false
    else
      offset = start_row
      limit = $PER_PAGE
    end

    conditions = []
    
    voice_logs,summary, page_info, agents = find_call_with_tags({
            :tags => tags_key,
            :tag_id => tag_id_key,
            :group_tag_id => group_id_key,
            :conditions => conditions,
            :order => orders,
            :offset => offset,
            :limit => limit,
            :page => page,
            :perpage => $PER_PAGE,
            :summary => true,
            :ctrl => ctrl})

    @voice_logs_ds = {:data => voice_logs, :page_info => page_info,:summary => summary }
    
  end

  def get_voice_log_list

    find_call_tag({:show_all => false, :timeline_enabled => false, :tag_enabled => true })

    render :json => @voice_logs_ds

  end

  def export

    show_all = ( (params[:type] =~ /true/) ? true : false )
      
    find_call_tag({:show_all => show_all, :timeline_enabled => false, :tag_enabled => false })

    @report = {}
    @report[:title_of] = Aohs::REPORT_HEADER_TITLE
    @report[:title] = "Tags Call List Report"

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
   
    @report[:fname] = "TagCallList"

    csvr = CsvReport.new
    csv_raw, filename = csvr.generate_report(@report)    

     log("Export","VoiceLogs",true,filename)

    send_data(csv_raw, :type => Aohs::MIMETYPE_CSV, :filename => filename)
  
  end
  
  def print

    show_all = ( (params[:type] =~ /true/) ? true : false )
      
    find_call_tag({:show_all => show_all, :timeline_enabled => false, :tag_enabled => false })

    @report = {}
    @report[:title_of] = Aohs::REPORT_HEADER_TITLE
    @report[:title] = "Tags Call List Report"

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
   
    @report[:fname] = "TagCallList"

    pdfr = PdfReport.new
    pdf_raw, filename = pdfr.generate_report_one(@report)

    log("Export","VoiceLogs",true,filename)

    send_data(pdf_raw, :file_type => Aohs::MIMETYPE_PDF, :filename => filename, :disposition => Aohs::DISPOSITION_PDF)

   end

  def show_tag
    @show_taglist = params[:tag]
  end

  def tree_update
    @favarite = Tags.find(:all)
    get_tag_list

    render :partial => 'tag_list'
  end

end
