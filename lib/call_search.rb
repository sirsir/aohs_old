require 'securerandom'
require 'axlsx'
require 'csv'

class CallSearch

  def initialize(conds)
    
    @keys       = clean_keys(conds)
    @conds      = {}
    @joins      = []
    @summary    = {}
    
    @v_tblname  = VoiceLog.table_name
    @tmp_id     = SecureRandom.hex(4)
    @usrs       = {}
    @grps       = {}
    @to_file    = false
    @query_mode = :db
    @sites      = {}
    @atlusrs    = {}
    LocationInfo.all.each { |l| @sites[l.id.to_s] = l.name }
    
    @perf_search = true
    
    # init values map
    @call_categories = {}
    CallCategory.not_deleted.all.each do |c|
      @call_categories[c.id.to_s] = c
    end
    
    get_current_user
    
    Rails.logger.info "CallSearch - received conditions: #{conds.inspect}"
    Rails.logger.info "CallSearch - accepted conditions: #{@keys.inspect}"
  end
  
  def to_hash
    
    build_conditions
    get_summary
    get_pageinfo
    
    result = get_result
    result[:summary_info] = @summary
    
    return result
  
  end

  def to_xlsx  
    
    export_to_file

    result = get_result
    save_to_xlsx_file(result)

  end
  
  def to_csv
  
    export_to_file
      
    result = get_result
    save_to_csv_file(result)
    
  end
  
  def file_id
    
    return @tmp_id
  
  end

  def self.get_exported_file(file_id)
    
    list = [
      "#{file_id}.xlsx",
      "#{file_id}.csv"
    ]
    
    list.each do |fname|
      fpath = File.join(Settings.server.directory.tmp,fname)
      if File.exists?(fpath)
        return fpath
      end
    end
    
    return nil
  
  end
  
  private

  def build_conditions
    
    conds   = @keys.clone
    whs     = {}
    
    # site_id, location
    if conds[:site_id].present?
      site_id = conds[:site_id].to_i
      if site_id > 0
        whs[:site_id_eq] = site_id
      end
    else
      sites = UserAttribute.where(user_id: @current_user_id).attr_name(:locations).first.attr_val.split("|").map { |lc| lc.to_i } rescue []
      unless sites.empty?
        whs[:site_id_in] = sites
      end
    end
    
    # start_time from:to
    
    fr_dt, to_dt = datetime_range(conds[:date_from], conds[:date_to])
    whs[:start_time_bet] = [fr_dt, to_dt]
    @st_datetime = fr_dt.strftime("%Y-%m-%d %H:%M:%S")
    @ed_datetime = to_dt.strftime("%Y-%m-%d %H:%M:%S")
    @st_date = fr_dt.strftime("%Y-%m-%d")
    @ed_date = to_dt.strftime("%Y-%m-%d")
    
    # call_direction
    
    if conds[:direction].present?
      cd_nm = get_call_direction(conds[:direction])
      whs[:call_direction_eq] = cd_nm  
    end

    # caller - ani
    
    if conds[:caller_no].present?
      ani = get_phone_no(conds[:caller_no])
      whs[:caller_no_like] = get_ani_numbers(ani,whs)
      @perf_search = false if whs[:caller_no_like].empty?
    end
    
    # dialed - dnis
    
    if conds[:dialed_no].present?
      dnis = get_phone_no(conds[:dialed_no])
      whs[:dialed_no_like] = get_dnis_numbers(dnis,whs)
      @perf_search = false if whs[:dialed_no_like].empty?
    end
    
    # extension number
    
    if conds[:extension].present?
      exts = get_extension_list(conds[:extension])
      whs[:extension_no_in] = exts 
    end
    
    # call_durection (from:to)
    
    if conds[:dur_fr].present? and valid_duration_fmt?(conds[:dur_fr])
      dur = get_duration_sec(conds[:dur_fr])  
      whs[:duration_gteq] = dur
    end
    
    if conds[:dur_to].present? and valid_duration_fmt?(conds[:dur_to])
      dur = get_duration_sec(conds[:dur_to])
      whs[:duration_lteq] = dur
    end
    
    # repeat dial
    if conds[:rdc_fr].present? or conds[:rdc_to].present?
      whs[:repeat_dial_count_bet] = [@st_date, @ed_date, conds[:rdc_fr], conds[:rdc_to], conds[:number_type]]
      if ['amivoice','acss','aeoncol'].include?(Settings.site.codename)
        whs[:call_direction_eq] = "o"
      end
    end
    
    # group of user
    
    if conds[:group_name].present?
      groups = get_groups_list(conds[:group_name])
      whs[:group_in] = groups unless groups == false 
    end
    
    if conds[:group_id].present?
      g_id = conds[:group_id].to_i
      whs[:group_in] = [g_id] 
    end
    
    # section
    
    if conds[:atlsection].present?
      sects = conds[:atlsection].split(": ").map { |s| s.strip }
      sects = SystemConst.find_const("atl-sections").namecode_start_with(sects).all
      unless sects.empty?
        sects = sects.map { |s| s.code }  
        @joins << "JOIN voice_log_atlusr_maps ON voice_logs.id = voice_log_atlusr_maps.voice_log_id"
        @joins << "JOIN user_atl_attrs ON voice_log_atlusr_maps.user_atl_id = user_atl_attrs.id"
        whs[:atl_section_id_in] = sects
      else
        whs[:id_eq] = 0
      end
    end
    
    # user (agent)
    
    if conds[:agent_name].present?
      agent_id = find_agent_name(conds[:agent_name])
      whs[:agent_in] = agent_id
    end
    
    if conds[:agent_id].present?
      agent_id = [conds[:agent_id].to_i]
      whs[:agent_in] = agent_id
    end
    
    # tags
    
    if conds[:call_tags].present?
      tags_id = get_tags_list(conds[:call_tags])
      whs[:taggings_in] = tags_id
    end
    
    if conds[:call_tags_id].present?
      tags_id = [conds[:call_tags_id]]
      whs[:taggings_in] = tags_id
    end
    
    # customer
    
    if conds[:customer_name].present?
      whs[:customer_name_like] = conds[:customer_name]
    end
    
    # call_id
    
    if conds[:call_id].present?
      whs[:call_id_eq] = conds[:call_id]
    end
    
    if conds[:keyword_id].present?
      whs[:keyword_in] = get_ketword_list(conds[:keyword_id])
    end

    # text / pharse
    
    if conds[:text].present?
      words = nil
      begin
        speaker_filter, conds[:text] = extract_phrase_label(conds[:text])
        s_words, m_words = AppUtils::TextPreprocessor.norm_text(conds[:text])
        words = s_words
        whs[:speaker] = speaker_filter
      rescue => e
        Rails.logger.error "Error convert text using, #{e.message}"
      end
      whs[:text] = words
      @highlight_words = m_words
      @query_mode = :es
    end
    
    # make join for transfer
    if Settings.qlogger.transfer_call == true and not (@query_mode == :es)
      @joins, whs = transfer_conds(whs)
    end
    
    if conds[:call_type].present?
      # call classification
      whs[:call_type_in] = [conds[:call_type]]
    end
    
    if conds[:reasons].present?
      # call reasons
      reasons = conds[:reasons].split(",")
      reasons = reasons.map { |r| r.split(":").last.strip }
      whs[:reasons_in] = reasons
      @query_mode = :es
    end
  
    # evaluation filter
    if conds[:qa_enable].present?
      q_join = evaluation_conds(conds)
      @joins << q_join unless q_join.nil?
    end

    # default filter
    
    if Settings.qlogger.transfer_call == true
      whs[:main_call] = true
    end
  
    @conds = clean_keys(whs)
    if @query_mode == :es
      @conds[:textscore] = Settings.callsearch.es_textscore
    end
    
    Rails.logger.info "CallSearch - mapped conditions: #{@conds.inspect}"
    
  end
  
  def extract_phrase_label(txt)
    # format [<channel/speaker>] <keyword>
    otxt = txt.to_s.match(/^(agent|customer|left|right)?(.+)/)
    unless otxt.nil?
      return otxt[1], otxt[2]
    end
    return nil, txt
  end
  
  def have_qa_forms?
    
    if @keys[:form_id].present? and not @keys[:form_id].empty?
      return true
    end
    
    return false
  
  end
  
  def evaluation_conds(conds)

    sql = []
    where = []
    
    if conds[:form_id].present? and (conds[:ev_sts].present? or conds[:evaluator_id].present?)
      where << "evaluation_logs.evaluation_plan_id = #{conds[:form_id]}"
    end
  
    if conds[:ev_sts].present?
      case conds[:ev_sts]
      when "E"
        # evaluated
        where << "evaluation_logs.evaluated_by > 0"
      when "C"
        # checked
        where << "evaluation_logs.checked_result IS NOT NULL"
      when "CC"
        # checked correct
        where << "evaluation_logs.checked_result = 'C'"
      when "CW"
        # checked wrong
        where << "evaluation_logs.checked_result = 'W'"
      end
    end
    
    if conds[:evaluator_id].present?
      where << "evaluation_logs.evaluated_by = #{conds[:evaluator_id]}"
    end
    
    if where.empty?
      return nil
    end
    
    f_date = Date.parse(conds[:date_from]).strftime("%Y-%m-%d")
    t_date = Date.parse(conds[:date_to]).strftime("%Y-%m-%d")
    
    where << "evaluation_logs.flag <> 'D'"
    where << "evaluation_calls.call_date BETWEEN '#{f_date}' AND '#{t_date}'"    
    where << "evaluation_plans.flag <> 'D'"
    
    sql << "SELECT DISTINCT evaluation_calls.voice_log_id"
    sql << "FROM evaluation_calls JOIN evaluation_logs"
    sql << "ON evaluation_calls.evaluation_log_id = evaluation_logs.id"
    sql << "JOIN evaluation_plans ON evaluation_plans.id = evaluation_logs.evaluation_plan_id"
    sql << "WHERE #{where.join(" AND ")} "
    
    join_sql = "JOIN (#{sql.join(" ")}) el ON voice_logs.id = el.voice_log_id"
    
    return join_sql
  
  end
  
  def transfer_conds(whs)
    
    joins   = []
    conds   = {}
    new_whs = {}
    select  = "DISTINCT(IF(ori_call_id='1' OR ori_call_id='',call_id,ori_call_id)) AS call_id"
    got_it  = false
    
    whs.each_pair do |cond, val|
      if transfer_cond_sub?(cond) 
        conds[cond] = val
        got_it = true
      else
        if transfer_cond_all?(cond)
          conds[cond] = val
        end
        new_whs[cond] = val
      end
    end
    
    if got_it and conds.length > 0
      sql = VoiceLog.select(select).search(conds).result.force_index(VoiceLog::IINDEX_STIME).to_sql
      joins << "JOIN (#{sql}) vs ON voice_logs.call_id = vs.call_id"
    else
      new_whs = whs
    end
    
    return joins, new_whs
  
  end
  
  def transfer_cond_sub?(cond)
    return [:dialed_no_like, :caller_no_like, :extension_no_in].include?(cond)
  end
  
  def transfer_cond_all?(cond)
    return [:start_time_bet, :call_direction_eq].include?(cond)
  end
  
  def get_result(start_row=@first_no, nrecs=@perpage)

    @no   = @first_no - 1 unless defined? @no
    ds    = []
    
    if @tt_records > 0
      if query_es_mode?
        ds = get_result_from_es(start_row, nrecs)
      else
        ds = get_result_from_db(start_row, nrecs)
      end      
    end
    
    return { data: ds }
  
  end

  def get_result_from_db(start_row, nrecs)

    ds = []
    
    vrs = VoiceLog.search(@conds).result
    vrs = vrs.select(select_cols)
    vrs = vrs.order(get_order)
    vrs = vrs.joins(@joins.uniq.join(" ")) unless @joins.empty?
    
    if start_row >= 0 and nrecs > 0
      vrs = vrs.offset(start_row - 1).limit(nrecs)
    end
    
    voice_logs = select_sql(vrs.to_sql)
    
    unless voice_logs.empty?
      voice_logs.each do |vl|
        ds << record_info(vl)
      end
    end
    
    voice_logs = []
    
    return ds
  
  end
  
  def get_result_from_es(start_row, nrecs)
    
    ds = []
    
    voice_logs = VoiceLogsIndex.make_voice_log_query(@conds)
    voice_logs = voice_logs.only(:id,:call_id,"recognition_results.result","recognition_results.channel","recognition_results.speaker_type")
    if start_row >= 0 and nrecs > 0
      voice_logs = voice_logs.offset(start_row - 1).limit(nrecs)
    end
    
    voice_logs.each do |vl|
      v = select_sql(VoiceLog.where(id: vl.id).limit(1).to_sql)
      next if v.empty?
      matched_str = get_matched_string(vl.recognition_results)
      ds << record_info(v.first, { found_sentence: matched_str, matched_score: vl._score })
    end
    
    return ds
  
  end
  
  def get_matched_string(recg_result)
    begin
      strs = []
      recg_result.each do |rx|
        if @conds[:speaker].to_s.downcase == "agent" and rx["channel"] == 1
          next
        elsif @conds[:speaker].to_s.downcase == "customer" and rx["channel"] == 0
          next
        end
        strs << StringFormat.highlight_text(StringFormat.sentense_format(rx["result"]),@highlight_words)
      end
      return (strs.sort { |a,b| a[:count] <=> b[:count] }).last[:text]
    rescue => e
      return ""
    end
  end
  
  def get_summary

    @tt_records = 0
    @tt_inbound = 0
    @tt_outbound = 0
    @tt_duration = 0
    @tt_inbound_duration = 0
    @tt_outbound_duration = 0
    
    if query_es_mode?
      get_summary_from_es
    else
      get_summary_from_db
    end
    
  end

  def get_summary_from_db

    groups = [
      #"DATE(#{@v_tblname}.start_time)",
      #"HOUR(#{@v_tblname}.start_time)",
      "#{@v_tblname}.call_direction"
    ]
    
    vls = VoiceLog.search(@conds).result
    vls = vls.select(select_summary).order(false)
    vls = vls.joins(@joins.join(" ")) unless @joins.empty?
    vls = vls.group(groups.join(","))
    vls = vls.force_index(VoiceLog::IINDEX_STIME)
    
    vs = []    
    if @perf_search
      vs = select_sql(vls.to_sql)
    end
  
    unless vs.empty?
      vs.each do |v|
        case v['call_direction']
        when 'i'
          @tt_inbound += v['total_records'].to_i
          @tt_inbound_duration += v['total_duration'].to_i
        when 'o'
          @tt_outbound += v['total_records'].to_i
          @tt_outbound_duration += v['total_duration'].to_i
        end
        @tt_records += v['total_records'].to_i
        @tt_duration += v['total_duration'].to_i
      end
    end
    
    @summary = @summary.merge!({
      total_records:        @tt_records,
      total_inbound:        @tt_inbound,
      total_outbound:       @tt_outbound,
      total_duration_sec:   @tt_duration,
      total_duration_hms:   StringFormat.format_sec(@tt_duration),
      total_duration_in_hms:  StringFormat.format_sec(@tt_inbound_duration),
      total_duration_out_hms: StringFormat.format_sec(@tt_outbound_duration)
    })
    
  end
  
  def get_summary_from_es
    
    v_index = VoiceLogsIndex.make_voice_log_query(@conds)
    
    aggs = {
      call_direction: {
        terms: {
          field: 'call_direction' },
        aggs: {
          sum_duration: {
            sum: {
              field: 'duration' }
          }
        }
      }
    }
    
    v_index = v_index.aggregations(aggs).search_type(:count)
    result = v_index.aggs['call_direction']['buckets']
    
    Rails.logger.info "Get ES query result, #{v_index.aggs.inspect}"
    
    result.each do |rs|
      case rs["key"]
      when "o"
        @tt_outbound += rs["doc_count"]
        @tt_outbound_duration += rs["sum_duration"]["value"]
      when "i"
        @tt_inbound += rs["doc_count"]
        @tt_inbound_duration += rs["sum_duration"]["value"]
      end
    end
    
    @tt_records = @tt_outbound + @tt_inbound
    @tt_duration = @tt_outbound_duration + @tt_inbound_duration
    
    @summary = @summary.merge!({
      total_records:        @tt_records,
      total_inbound:        @tt_inbound,
      total_outbound:       @tt_outbound,
      total_duration_sec:   @tt_duration,
      total_duration_hms:   StringFormat.format_sec(@tt_duration),
      total_duration_in_hms:  StringFormat.format_sec(@tt_inbound_duration),
      total_duration_out_hms: StringFormat.format_sec(@tt_outbound_duration)
    })
    
  end
  
  def get_keyword_summary_from_es
    
  end
  
  def get_pageinfo
    
    perpage = @keys[:perpage].to_i
    page    = @keys[:page].to_i
    
    @tt_pages   = 0
    @first_no   = 0
    @last_no    = 0
    @perpage    = perpage
    @page       = page

    if @tt_records > 0
      @tt_pages = (@tt_records / perpage.to_f).ceil
    end

    if @tt_records <= 0
      @page = 0
    elsif @page <= 0 or @page > @tt_pages
      @page = 1
    end

    if @tt_records > 0
      @first_no = ((@page - 1) * @perpage) + 1
      @last_no  = ((@page < @tt_pages) ? ((@first_no) + @perpage - 1) : @tt_records)
    end

    @summary = @summary.merge({
      perpage:      @perpage,
      current_page: @page,
      total_pages:  @tt_pages,
      first_row:    @first_no,
      last_row:     @last_no
    })
  
  end
  
  def update_export_options
  
    # change value for export
    
    @first_no = 1
    @perpage  = Settings.callsearch.export.maximun_recs
    
  end
  
  def export_to_file
    
    @to_file = true
    
    build_conditions
    get_summary
    get_pageinfo
    update_export_options
  
  end
  
  def get_order
    
    order_field = ""
    order_info  = @keys[:order_by].to_s.strip
    o_col, o_by = order_info.split(/ /, 2)

    case o_col.to_s.strip
    when 'caller_no', 'caller'
      order_field = "#{@v_tblname}.ani"
    when 'dialed_no', 'dialed'
      order_field = "#{@v_tblname}.dnis"
    when 'ext', 'extension'
      order_field = "#{@v_tblname}.extension"
    when 'duration'
      order_field = "#{@v_tblname}.duration"
    when 'cd', 'direction'
      order_field = "#{@v_tblname}.call_direction"
    when 'agent_name'
      @joins << "LEFT JOIN users ON voice_logs.agent_id = users.id"
      order_field = "users.login"
    when 'ng_word_count'
      @joins << "LEFT JOIN voice_log_counters ON voice_logs.id = voice_log_counters.voice_log_id AND voice_log_counters.counter_type = 4"
      order_field = "voice_log_counters.valu"
    when 'redial_call_cnt'
      unless @conds.has_key?(:repeat_dial_count_bet)
        @joins << PhonenoStatistic.create_joinsql_for_voice_logs({ sdate: @st_date, edate: @ed_date })
      end
      order_field = "rpc.repeated_count"
    else
      order_field = "#{@v_tblname}.start_time"
    end
    
    case o_by.to_s.strip
    when "asc"
      order_field = order_field.concat("")
    when "desc"
      order_field = order_field.concat(" DESC")
    else
      order_field = order_field.concat(" DESC")
    end
    
    order_field << ", #{@v_tblname}.id DESC"
    return order_field
  end
  
  def record_info(vl, adds={})
    
    @no       += 1
    agent_name = ""
    group_name = ""
    
    usr   = get_user_info(vl['agent_id'])
    cinf  = get_counters(vl)
    
    # show transfer call
    tr_calls, tr_flag = [], false
    if Settings.qlogger.transfer_call == true
      tr_calls, tr_flag = get_childs(vl)
    end
    
    # tags
    vtags = []
    if cinf[:tagging] > 0
      vtags = get_tags_n(vl) 
    end
    
    # favourite
    vfav = nil
    #if not file_mode? and cinf[:fav] > 0
    #  vfav = check_favourite_call(vl['id'])
    #end
    
    # els data
    els = get_els_data(vl)
    
    vcate = []
    if cinf[:cate] >= 0
      vcate = get_call_type(vl['id'])
    end
    is_private = false
    unless vcate.empty?
      @pvt = CallCategory.private_call.first unless defined?(@pvt)
      unless @pvt.nil?
        is_private = vcate.include?({ title: @pvt.title })
      end
    end
    
    # customer
    cus = get_customer(vl['id'])
    customer_name = cus[:customer_name]
    
    # emotion/sactisfaction
    cu_emotion = {}
    
    # custom attributes
    custom_fields = get_custom_attributes(vl['id'])
    
    # css row class
    rklass = []
    rklass << "warn" if vl['duration'].to_i >= Settings.callsearch.warn_duration_sec.to_i
    
    if Settings.callsearch.highlight_ngwords.to_i > 0
      if cinf[:ng_count].to_i >= Settings.callsearch.highlight_ngwords.to_i
        rklass << "ngwords"
      end
    end
    
    evl = get_evaluate_info(vl)
    atlu = get_atluser_log(vl)
    unless atlu.nil?
      custom_fields = custom_fields.merge(atlu)  
    end
    
    return ({
      no:           row_number(@no),
      id:           vl['id'].to_i,
      sys:          vl['system_id'].to_i,
      dev:          vl['device_id'].to_i,
      chn:          vl['channel_id'].to_i,
      call_date:    vl['start_time'].to_formatted_s(:web),
      cd:           get_call_direction_n(vl['call_direction']),
      cd_css:       get_call_direction_n(vl['call_direction']).downcase,
      caller_no:    StringFormat.format_phone(vl['ani']),
      caller_no_type: check_tel_number_type(vl['ani']), 
      dialed_no:    StringFormat.format_phone(vl['dnis']),
      dialed_no_type: check_tel_number_type(vl['dnis']),
      ext:          StringFormat.format_ext(vl['extension']),
      duration:     StringFormat.format_sec(vl['duration'].to_i),
      agent_id:     vl['agent_id'].to_i,
      agent_name:   usr[:display_name],
      group_name:   usr[:group_name],
      customer_name: customer_name,
      tags:         vtags,
      permiss:      call_permission?(vl['agent_id'].to_i,usr[:role_priority]),
      kls:          rklass.join(" "),
      childs:       tr_calls,
      sbflg:        tr_flag,
      fav:          vfav,
      u_score:      get_call_score(vl['id']),
      ctype:        vcate,
      evl:          evl,
      redial_call_cnt: get_redial_call_count(vl),
      emotion:      cu_emotion,
      site_name:    @sites[vl['site_id'].to_s],
      found_sentence: adds[:found_sentence],
      matched_score: adds[:matched_score].to_f.round(6),
      hasfile:      true,
      private_call: is_private,
      ng_word_count: cinf[:ng_count],
      note:         els[:note]
    }).merge(custom_fields)
  
  end
  
  def check_tel_number_type(number)
    pno = PhoneNumber.new(number)
    if pno.real_number.length > 5
      tel = TelephoneInfo.find_number(pno.real_number).first
      unless tel.nil?
        return tel.type_name
      end
    end
    return nil
  end
  
  def get_redial_call_count(vl)
    # repeat dial count
    if vl['call_direction'] == 'o'
      return PhonenoStatistic.get_redial_count_per_day(vl['start_time'].to_date, vl['dnis'])
    end
  end
  
  def get_atluser_log(vl)
    alog = VoiceLogAtlusrMap.where(voice_log_id: vl['id']).first
    unless alog.nil?
      t_key = alog.user_atl_id.to_s
      if @atlusrs[t_key].nil?
        ulog = UserAtlAttr.where(id: alog.user_atl_id).first
        unless ulog.nil?
          @atlusrs[t_key] = {
            section_id: ulog.section_id,
            perf_group_id: ulog.performance_group_id,
            team_id: ulog.team_id,
            operator_id: ulog.operator_id
          }
        end
      end
      return @atlusrs[t_key]
    end
    return {}
  end
  
  def get_call_type(id)  
    cates = []
    call_cates = CallClassification.select(:call_category_id).not_deleted.where({voice_log_id: id}).all
    call_cates.each do |c|
      cate = @call_categories[c.call_category_id.to_s]
      unless cate.nil?
        cates << { title: cate.title }
      end  
    end
    return cates
  end

  def get_call_score(id)
    return nil
  end
  
  def get_customer(id)
    ctm = CallCustomer.where({ voice_log_id: id }).first
    unless ctm.nil?
      cus = ctm.customer
      unless cus.nil?
        return {
          customer_id: cus.id,
          customer_name: cus.name
        }
      end
    end
    return {}
  end
  
  def get_emotion_call(id)
    return VoiceLog.get_emotion_id(id).id
  end
  
  def get_custom_attributes(id)
    custom = {}
    atrs = VoiceLogAttribute.where({ voice_log_id: id }).default_select.all
    unless atrs.empty?
      atrs.each do |atr|
        case atr.attr_type
        when VoiceLogAttribute::ATTR_CALL_RESULT
          custom[:call_result] = atr.attr_val
        end
      end
    end
    return custom
  end

  def check_favourite_call(id)
    
    cnt = CallFavourite.where({voice_log_id: id, user_id: @current_user_id }).count('0')
    return ((cnt <= 0) ? 'no-favourite' : 'favourited')
  
  end
  
  def get_tags_n(vl)
    
    tgs = Tagging.select("tags.id, tags.name")
                  .joins(:tag)
                  .where(["taggings.tagged_id = ?",vl['id']])
                  .limit(Settings.callsearch.max_taggings)
    tgs = select_sql(tgs.to_sql)

    unless tgs.empty?
      list = tgs.map { |t| { id: t['id'], name: t['name'] } }
      return list
    end
    
    return []
    
  end
  
  def get_els_data(vl)
    crr = CallRecognitionResult.get_detail(vl['id'],[:au_taggings])
    unless crr.nil?
      return {
        note: crr.note
      }
    end
    return {}  
  end
  
  def record_info_sb(vl,i)
    
    usr = get_user_info(vl['agent_id'])
    evl = {}
    
    has_file = false
    if not vl['voice_file_url'].nil? and vl['voice_file_url'].length > 5
      has_file = true
    end
    
    return {
      no:           row_number(@no),
      id:           vl['id'].to_i,
      sys:          vl['system_id'].to_i,
      dev:          vl['device_id'].to_i,
      chn:          vl['channel_id'].to_i,
      call_date:    vl['start_time'].to_formatted_s(:web),
      cd:           get_call_direction_n(vl['call_direction']),
      cd_css:       get_call_direction_n(vl['call_direction']).downcase,
      caller_no:    StringFormat.format_phone(vl['ani']),
      dialed_no:    StringFormat.format_phone(vl['dnis']),
      ext:          StringFormat.format_ext(vl['extension']),
      duration:     StringFormat.format_sec(vl['duration'].to_i),
      agent_id:     vl['agent_id'].to_i,
      agent_name:   usr[:display_name],
      group_name:   usr[:group_name],
      tags:         get_tags_n(vl),
      evl:          evl,
      permiss:      call_permission?(vl['agent_id'].to_i, usr[:role_priority]),
      hasfile:      has_file
    }

  end
  
  def get_childs(v)
    
    result  = []
    call_id = v['call_id']
    
    vlt = VoiceLog.select(select_cols).where(ori_call_id: call_id)
    vlt = select_sql(vlt.to_sql)
    
    unless vlt.empty?
      vlt.each_with_index do |vl,i|
        result << record_info_sb(vl,i)
      end
    end
    
    return result, (not result.empty?)
  
  end

  def get_counters(v)
    
    rs  = Hash.new(0)
    
    recs = VoiceLogCounter.select([:counter_type, :valu]).where(voice_log_id: v['id']).order(false).all
    recs.each do |r|
      case r.counter_type
      when VoiceLogCounter::CT_TAGGING
        rs[:tagging] = r.record_count
      when VoiceLogCounter::CT_FAV
        rs[:fav] = r.record_count
      when VoiceLogCounter::CT_CACLASS
        rs[:cate] = r.record_count
      when VoiceLogCounter::CT_NGKEYWORD
        rs[:ng_count] = r.record_count
      end
    end
    
    return rs
  
  end
  
  def datetime_range(fr_d,to_d)
    
    return get_datetime(fr_d), get_datetime(to_d)
    
  end
  
  def get_datetime(d)
    
    nd = d.clone
    case d
    when /(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})/i
      nd = "#{d}:00"
    when /(\d{4}-\d{2}-\d{2})/i
      nd = "#{d} 00:00:00"
    end
    
    t = Time.parse(nd)
    if t >= Time.now
      t = Time.now - Settings.callsearch.calltime_delay_sec.to_i
    end
    
    return t
  
  end

  def get_call_direction(v)
    
    case v.to_s.downcase
    when 'i', 'in', 'inbound'
      return 'i'
    when 'o', 'out', 'outbound'
      return 'o'
    end
    
    return nil
  
  end
  
  def get_call_direction_n(v)
    
    case v.to_s
    when 'i'
      return 'In'
    when 'o'
      return 'Out'
    else
      return ''
    end
  
  end
  
  def get_phone_no(v)
    
    phone_no  = v.to_s.strip
    phone_len = phone_no.length
    phones    = []
  
    phones << "%#{phone_no}%"
    
    if phone_len >= 8
      
      # [9]0...
      if phone_no[0,2] == "90"
        phone_no = phone_no[1..-1]
        phones << "#{phone_no}%"
      end
      
      # 0...
      if phone_no[0,1] == "0"
        phone_no = phone_no[1..-1]
        phones << "#{phone_no}%"
      end
      
    end
    
    return phones
  
  end
  
  def get_ani_numbers(number,whs)
    
    numbers = []
    df, dt  = whs[:start_time_bet]
    
    sql = VoiceLog.select("DISTINCT ani")
                  .start_time_bet(df,dt)
                  .caller_no_like(number)
                  .force_index(VoiceLog::IINDEX_STIME)
                  .limit(Settings.callsearch.max_poss_numbers).to_sql
    result = select_sql(sql)
    
    numbers = result.map { |r| r['ani'] }
    
    return numbers
  
  end
  
  def get_dnis_numbers(number,whs)
    
    numbers = []
    df, dt  = whs[:start_time_bet]
    
    sql = VoiceLog.select("DISTINCT dnis")
                  .start_time_bet(df,dt)
                  .dialed_no_like(number)
                  .force_index(VoiceLog::IINDEX_STIME)
                  .limit(Settings.callsearch.max_poss_numbers).to_sql
    result = select_sql(sql)
    
    numbers = result.map { |r| r['dnis'] }
    
    return numbers
  
  end

  def get_current_user
    @current_user_id = nil
    @current_user_role_priority = nil
    
    if defined? @keys[:current_user_id] and @keys[:current_user_id].to_i > 0
      @current_user_id = @keys[:current_user_id].to_i
      tuser = User.select(:role_id).where(id: @current_user_id).first
      unless tuser.nil?
        trole = Role.where(id: tuser.role_id).first
        unless trole.nil?
          @current_user_role_priority = trole.priority_no.to_i
        end
      end
    end
    
    # permiss users and groups
    unless @current_user_id.nil?
      no_chk_required = SysPermission.can_do?(@current_user_id,"voice_logs","disabled_call_permission")
      unless no_chk_required
        user = User.select([:id, :role_id]).where(id: @current_user_id).first
        unless user.nil?
          @permiss_users = user.permiss_users
          if user.user_attr(:unknown_call).is_checked?
            @permiss_users << 0
          end
        end
      end
    end
    
  end
  
  def get_ketword_list(keyword_id)
    
    keyword = Keyword.select([:id,:parent_id]).where(id: keyword_id).first
    rs = keyword.childrens.map { |k| k.id }
    rs.concat([keyword.id])
    
    return rs
  
  end
  
  def get_evaluate_info(vl)
    
    return {} unless is_qa_mode?
    
    result = { status: "not-evaluate", other_flg: false }
    result_set = []
    
    selects = {
      evaluation_calls: [:evaluation_log_id],
      evaluation_logs: [:id, :evaluation_plan_id]
    }
    
    ecs = EvaluationCall.joins("LEFT JOIN evaluation_logs ON evaluation_logs.id = evaluation_calls.evaluation_log_id")
    ecs = ecs.where(["evaluation_calls.voice_log_id = ? AND evaluation_logs.flag <> 'D'", vl["id"].to_i])
    ecs = ecs.order(evaluation_log_id: :desc).all
    
    if have_qa_forms?
      ecs = ecs.where({ evaluation_plan_id: @keys[:form_id] })
    end
    
    unless ecs.empty?
      ecs.each do |ec|
        rs = {
          status: "not-evaluate",
          evaluated_by: nil,
          checked_by: nil,
          form: nil
        }
        
        el = EvaluationLog.not_deleted.where(id: ec.evaluation_log_id).first
        unless el.nil?
          next if el.evaluation_form.flag == 'D'
          rs[:form] = el.evaluation_form.name
          rs[:status] = 'evaluated'
          rs[:w_score] = StringFormat.num_format(el.weighted_score)
          if not el.checked_by.nil? and not el.checked_result.nil?
            case el.checked_result
            when 'W'
              rs[:status] = 'checked-wrong'
            when 'C'
              rs[:status] = 'checked-correct'
            else
              rs[:status] = 'checked'
            end
          end

          unless el.evaluated_by.nil?
            evr = get_user_info(el.evaluated_by)
            rs[:evaluated_by] = evr[:display_name]
          end
        
          unless el.checked_by.nil?
            chr = get_user_info(el.checked_by)
            rs[:checked_by] = chr[:display_name]
          end
          
          if result_set.empty?
            result = rs.clone
          end
          result_set << { evl: rs }
          
        end
      end 
    end
    
    if result_set.length > 1
      result_set.delete_at(0)
      result[:other_flg] = true
      result[:other] = result_set    
    end
    
    return result
  
  end
  
  def call_permission?(agent_id, role_priority=0)
    # to check access level to listen the call
    # allowed user/role
    # role priority
    
    allow = true
    role_priority = role_priority.to_i
    
    if not file_mode? and not @current_user_id.nil? and defined? @permiss_users
      allow = @permiss_users.include?(agent_id)
    end
    
    if allow
      if not @current_user_role_priority.nil? and @current_user_role_priority < role_priority 
        # not allowed to listen if role is upper
        allow = false
      end
    end
    
    return allow
  end
  
  def get_extension_list(v)
    ext = v.to_s.strip
    exts = [ext]
    # aeon - add leading number (5,6)
    if ext.length == 4
      exts = exts.concat([5,6].map { |n| "#{n}#{ext}"})
    elsif ext.length == 5
      exts << ext[1..4]
      exts << ext
    end
    return exts.uniq
  end

  def get_duration_sec(v)
    v = v.to_s.strip.gsub(/\:+/,":")
    unless v.match(/^(\d{1,3}):(\d{2})$/).nil?
      secs = time_to_sec(v)
    else
      secs = time_to_sec(v.to_i)
    end
    return secs
  end
  
  def valid_duration_fmt?(v)
    v = v.to_s.strip.gsub(/\:+/,":") 
    return (not v.match(/^(\d{1,3}):(\d{2})$/).nil?)
  end
  
  def get_groups_list(v)
    groups = Group.select(:id).where(["short_name LIKE ?",v]).all
    unless groups.empty?
      return groups.map { |g| g.id }  
    end
    return false
  end
  
  def get_tags_list(v)
    tags = Tag.select(:id).where(["name LIKE ?","%#{v}%"]).all
    unless tags.empty?
      return tags.map { |t| t.id }
    end
    return false
  end
  
  def get_user_info(usr_id)
    user_id_s = usr_id.to_s
    if @usrs[user_id_s].nil?
      x_select = [
        "users.id", "users.login", "users.full_name_th", "users.full_name_en", "users.role_id"
      ]
      x_sql = User.select(x_select).where(id: usr_id).limit(1).to_sql
      usr = select_sql(x_sql).first
      unless usr.nil?
        ugm = select_sql(GroupMember.select(:group_id).only_member.where(user_id: usr['id']).limit(1).to_sql).first
        r_priority = Role.where(id: usr["role_id"]).first.priority_no.to_i rescue 0
        grp_id = (ugm.nil? ? 0 : ugm['group_id'])
        if @grps[grp_id].nil? and grp_id > 0
          grp = select_sql(Group.select([:id,:short_name]).where(id: grp_id).limit(1).to_sql).first
          @grps[grp_id] = {
            id: grp['id'],
            name: grp['short_name'],
          }
        end
        grp = @grps[grp_id]
        @usrs[usr_id] = {
          display_name: User.display_name(User.new(usr)),
          group_id: (grp.nil? ? nil : grp[:id]),
          group_name: (grp.nil? ? nil : grp[:name]),
          role_priority: r_priority
        }
      else
        @usrs[usr_id] = {
          display_name: "",
          group_id: 0,
          group_name: "",
          role_priority: r_priority
        }
      end
    end
    return @usrs[usr_id]
  end
  
  def find_agent_name(v)
    if v =~ /(none)/ or v =~ /(unknown)/ or v =~ /(blank)/
      # support unknow agent
      return [0]
    else
      users = User.select(:id).name_like(v).all
      unless users.empty?
        return users.map { |u| u.id }
      end
    end
    return false
  end
  
  def clean_keys(conds)
    conds.each {|key, value| conds.delete(key) if value.to_s.strip.empty? }
  end
  
  def time_to_sec(v)
    # input format (m)mm:ss
    if v.is_a?(String)
      ts = v.match(/^(\d{1,3}):(\d{2})$/)
      t_min = ts[1].to_i
      t_sec = ts[2].to_i
      s = (t_min * 60) + t_sec
    else
      t_min = v
      s = (t_min * 60)
    end
    return s
  end
  
  def select_cols
    
    cols = [
      'id',
      'site_id',
      'system_id',
      'device_id',
      'channel_id',
      'ani',
      'dnis',
      'extension',
      'duration',
      'agent_id',
      'voice_file_url',
      'call_direction',
      'start_time',
      'call_id',
      'ori_call_id'
    ].map { |c| [@v_tblname,'.',c].join }
    
    return cols
  
  end
  
  def select_summary
    
    cols = [
      #"DATE(#{@v_tblname}.start_time) AS call_date",
      #"HOUR(#{@v_tblname}.start_time) AS call_hour",
      "#{@v_tblname}.call_direction",
      "COUNT(0) AS total_records",
      "SUM(#{@v_tblname}.duration) AS total_duration"
    ]
    
    return cols
  
  end
  
  def row_number(n)
    
    return n
  
  end

  def save_to_xlsx_file(result)
    
    ax = Axlsx::Package.new
    wb = ax.workbook
    ws = wb.add_worksheet(name: "call list")
    
    # header columns
    cols = export_cols
    ws.add_row cols
    
    # data
    result[:data].each do |r|
      ro = [
        r[:call_date],
        r[:caller_no],
        r[:dialed_no],
        r[:ext],
        r[:duration],
        r[:cd],
        r[:agent_name],
        r[:group_name],
        join_catename(r[:ctype]),
        join_tagname(r[:tags])
      ]
      ws.add_row ro, types: [nil, :string, :string, :string]
    end
    
    fname = output_fname(:xlsx)
    ax.serialize fname
    
    fname = rename_file_prefix(fname)
    
  end

  def save_to_csv_file(result)
    
    fname = output_fname(:csv) 
    
    CSV.open(fname,'wb') do |csv|
      
      # header columns
      cols = export_cols
      csv << cols
      
      # data
      result[:data].each_with_index do |r,i|
        ro = [
          r[:call_date],
          r[:caller_no],
          r[:dialed_no],
          r[:ext],
          r[:duration],
          r[:cd],
          r[:agent_name],
          r[:group_name],
          join_catename(r[:ctype]),
          join_tagname(r[:tags])
        ]
        csv << ro
      end
      
    end 
    
    fname = rename_file_prefix(fname)
    
  end
  
  def join_tagname(tags)
    
    return (tags.map { |t| t[:name] }).join(", ")
  
  end
  
  def join_catename(ctype)
    
    return (ctype.map { |t| t[:title] }).join(", ")
  
  end
  
  def rename_file_prefix(fpath)
  
    if File.exists?(fpath)
      new_fpath = fpath.gsub(".tmp","")
      File.rename(fpath, new_fpath)
    end
    
    return fpath
    
  end
  
  def output_fname(fext)
    
    fname = [@tmp_id,"tmp",fext.to_s].join(".")
    return File.join(Settings.server.directory.tmp,fname)
  
  end
  
  def is_qa_mode?
    return (@keys[:qa_enable] == "true")
  end
  
  def query_mode?(mode)
    @query_mode == mode  
  end
  
  def query_es_mode?
    query_mode?(:es)  
  end

  def query_db_mode?
    query_mode?(:db)  
  end
  
  def file_mode?
    
    if defined? @to_file
      return @to_file
    end
    
    return false
  
  end
  
  def export_cols
    
    cols = [
      'date/time',
      'caller no',
      'dialed no',
      'extension',
      'duration',
      'calldirection',
      'agent name',
      'group',
      'flag',
      'tags'
    ]
    
    cols
    
  end
  
  def select_sql(sql)
    
    return ActiveRecord::Base.connection.select_all(sql)  
  
  end
  
end