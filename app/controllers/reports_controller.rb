class ReportsController < ApplicationController
  
  before_action :authenticate_user!
  
  def index
    # nothing
  end

  def call_overview
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::CallSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::CallSummary.new(report_params)
        render json: report.get_result
      }
    end    
  end
  
  def agent_call_usage
    respond_to do |format|
      format.html
      format.xlsx {
        r_params = report_params
        r_params[:row_by] = :agent
        report = ReportingTool::AgentCallUsage.new(r_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        r_params = report_params
        r_params[:row_by] = :agent
        report = ReportingTool::AgentCallUsage.new(r_params)
        render json: report.get_result
      }
    end
  end
  
  def agent_call_summary
    respond_to do |format|
      format.html
      format.xlsx {
        r_params = report_params
        r_params[:row_by] = :agent
        report = ReportingTool::AgentCallSummary.new(r_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        r_params = report_params
        r_params[:row_by] = :agent
        report = ReportingTool::AgentCallSummary.new(r_params)
        render json: report.get_result
      }
    end
  end

  def group_call_summary
    respond_to do |format|
      format.html
      format.xlsx {
        r_params = report_params
        r_params[:row_by] = :group
        report = ReportingTool::AgentGroupCallSummary.new(r_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        r_params = report_params
        r_params[:row_by] = :group
        report = ReportingTool::AgentGroupCallSummary.new(r_params)
        render json: report.get_result
      }
    end
  end
  
  def hourly_call_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::HourlyCallSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::HourlyCallSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def call_tags
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::CallTagSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::CallTagSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def top_repeated_outbound
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::RepeatedOutboundCallCount.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::RepeatedOutboundCallCount.new(report_params)
        render json: report.get_result
      }
    end
  end

  def top_repeated_inbound
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::RepeatedInboundCallCount.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::RepeatedInboundCallCount.new(report_params)
        render json: report.get_result
      }
    end
  end

  def agent_keyword_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AgentKeywordSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AgentKeywordSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
    
  def private_call_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::PrivateCallSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::PrivateCallSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def monitoring_usage
    @past_days = Settings.statistics.callview.past_days
    
    case params[:format]
    when "json"
      render json: call_view_data
    end
  end

  def call_view_data
    
    data  = []
    sel_1 = "user_id, count(id) AS record_count"
    sel_2 = "date(created_at) AS report_date,count(id) AS record_count"
    
    recs  = CallTrackingLog.select(sel_1).group("user_id").order("count(id) DESC").past_days(@past_days).all
    dates = StatisticCalendar.select("DISTINCT stats_date").past_days(@past_days).all
    
    recs.each_with_index do |rec,i|
      ds = CallTrackingLog.select(sel_2).group("date(created_at)").order("date(created_at)").where(user_id: rec.user_id).past_days(@past_days).all
      ddate = []
      dcount = []
      dates.each do |dt|
        ddate << dt.stats_date.to_formatted_s(:web)
        dcount << ((ds.select { |s| s.report_date == dt.stats_date}).first.record_count rescue 0)
      end
      data << {
        no:         i+1,
        user_id:    rec.user_id,
        name:       User.where(id: rec.user_id).first.login,
        total_view: rec.record_count,
        ddate: ['x'].concat(ddate),
        dcount: ['count'].concat(dcount)
      }
    end
    
    return data
  
  end
    
  def notif_rec_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::NotiRecommendationAgentSummary.new(report_params)
        xfile = report.to_xlsx
        set_download_success_flag
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::NotiRecommendationAgentSummary.new(report_params)
        render json: report.get_result
      }
    end
  end

  def notif_keyword_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::NotiKeywordAgentSummary.new(report_params)
        xfile = report.to_xlsx
        set_download_success_flag
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::NotiKeywordAgentSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  private
  
  def date_range_params(date_range=params[:date_range])    
    ds = Date.today
    dt = Date.today
    unless date_range.blank?
      dates = params[:date_range].split(" - ")
      ds = Date.parse(dates.first.strip)
      dt = Date.parse(dates.last.strip)
    end
    return ds, dt
  end
  
  def report_params
    pams = {}
    
    if params[:period_by].present?
      pams[:period_by] = params[:period_by].downcase 
    end
    
    if params[:row_by].present?
      pams[:row_by] = params[:row_by].downcase 
    end
    
    if params[:date_range].present?
      dt, ds = date_range_params(params[:date_range])
      pams[:sdate] = dt
      pams[:edate] = ds
      pams[:sdatetime] = Time.parse(dt.strftime("%Y-%m-%d")).beginning_of_day
      pams[:edatetime] = Time.parse(ds.strftime("%Y-%m-%d")).end_of_day
      keep_session_param(:date_range, params[:date_range])
    end

    if params[:group_name].present?
      pams[:group_name] = params[:group_name]
    end
    
    if params[:agent_name].present?
      pams[:agent_name] = params[:agent_name]
      pams[:user_id] = find_user_id(params[:agent_name])
    end
    
    if params[:user_name].present?
      pams[:agent_name] = params[:user_name]
      pams[:user_id] = find_user_id(params[:user_name])
    end

    if params[:limit].present?
      pams[:limit] = params[:limit].to_i
    end

    if params[:call_direction].present?
      pams[:call_direction] = params[:call_direction]
    end
    
    if params[:phone_type].present?
      pams[:phone_type] = params[:phone_type].to_s
    end
    
    if params[:section_name].present?
      kws = params[:section_name].strip.split(": ")
      pams[:section_name] = kws.map { |sn| sn.strip }
    end
    
    if params[:keyword].present?
      pams[:keyword] = params[:keyword]
    end
    
    if params[:tag_id].present?
      # convert to array
      pams[:tag_id] = [params[:tag_id].to_i]
    end
    
    if params[:scols].present?
      pams[:columns] = params[:scols]  
    end
    
    if params[:duration_fmt].present?
      pams[:duration_fmt] = params[:duration_fmt].to_sym
    end
    
    return pams 
  end
  
  def keep_session_param(name, value=nil)
    # key name for reporting params
    # prefix: report_<name>
    keyname = "report_#{name.to_s}"
    session[keyname] = value
  end
  
  def find_user_id(name)
    if not name.blank? and not name.to_s.empty?
      users = User.select(:id).only_active.full_name_cont(name).all
      unless users.empty?
        return users.map { |u| u.id }
      else
        return [0]
      end
    end
    return nil
  end

  def find_group_id(name)
    if not name.blank? and not name.to_s.empty?
      groups = Group.select(:id).not_deleted.name_like(name).all
      unless groups.empty?
        return groups.map { |u| u.id }
      else
        return [0]
      end
    end
    return nil
  end
  
  def set_download_success_flag
    cookies['fileDownload'] = true 
  end
  
end
