class EvaluationReportsController < ApplicationController

  before_action :authenticate_user!
  
  def agent_detail
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AgentEvaluationDetail.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AgentEvaluationDetail.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def agent_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AgentEvaluationSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AgentEvaluationSummary.new(report_params)
        render json: report.get_result
      }
    end
  end

  def group_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::GroupEvaluationSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::GroupEvaluationSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def evaluator_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::EvaluatorSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::EvaluatorSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def evaluator_call_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::EvaluatorCallSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::EvaluatorCallSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def acs_greeting
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AcsGreetingSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AcsGreetingSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def acs_agent_call_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AcsAgentCallSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AcsAgentCallSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def acs_ngusage_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AcsNgUsageCallSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AcsNgUsageCallSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def acs_call_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AcsCallSummary.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AcsCallSummary.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def acs_evaluation_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AcsEvaluationCnt.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AcsEvaluationCnt.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def attachment_list    
    respond_to do |format|
      format.html {
        @doc_templates = DocumentTemplate.not_deleted.order_by_default
        unless @doc_templates.empty?
          @document = DocumentTemplate.where(id: params[:template_id]).first
          @document = @doc_templates.first if @document.nil?
        else
          @document = DocumentTemplate.new
        end
        @all_attachments = EvaluationDocAttachment.search(attch_conditions_params).result        
      }
      format.xlsx {
        report = ReportingTool::DocumentList.new(params[:template_id],{ conditions: attch_conditions_params })
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
    end
  end
  
  def check_summary
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::CheckingSummaryReport.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::CheckingSummaryReport.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def check_detail
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::CheckingDetailReport.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::CheckingDetailReport.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  def asst_details
    respond_to do |format|
      format.html
      format.xlsx {
        report = ReportingTool::AsstDetailLog.new(report_params)
        xfile = report.to_xlsx
        cookies['fileDownload'] = true
        send_file xfile[:path]
      }
      format.json {
        report = ReportingTool::AsstDetailLog.new(report_params)
        render json: report.get_result
      }
    end
  end
  
  #def evaluation_score
  #  
  #  case req_format
  #  when :json
  #    report = ReportingTool::ScoreReport.new(report_params)
  #    result = report.get_result
  #    render json: result
  #  
  #  when :xlsx
  #    report = ReportingTool::ScoreReport.new(report_params)
  #    xfile = report.to_xlsx
  #    cookies['fileDownload'] = true
  #    send_file xfile[:path]
  #  end
  #  
  #end
  #
  #def evaluator_statistic
  #
  #  case req_format
  #  when :json
  #    report = EvaluationReport::EvaluatorStatistic.new(report_params)
  #    result = report.get_result
  #    render json: result
  #    
  #  when :xlsx
  #    report = EvaluationReport::EvaluatorStatistic.new(report_params)
  #    xfile = report.to_xlsx
  #    cookies['fileDownload'] = true
  #    send_file xfile[:path]
  #  end
  #  
  #end
  #
  #def evaluator_performance
  #
  #  case req_format
  #  when :json
  #    report = EvaluationReport::EvaluatorPerformance.new(report_params)
  #    result = report.get_result
  #    render json: result
  #    
  #  when :xlsx
  #    report = EvaluationReport::EvaluatorPerformance.new(report_params)
  #    xfile = report.to_xlsx
  #    cookies['fileDownload'] = true
  #    send_file xfile[:path]
  #  end
  #  
  #end
  #
  #def agent_score_summary
  #
  #  case req_format
  #  when :json
  #    report = EvaluationReport::AgentScoreSummary.new(report_params)
  #    result = report.get_result
  #    render json: result
  #    
  #  when :xlsx
  #    report = EvaluationReport::AgentScoreSummary.new(report_params)
  #    xfile = report.to_xlsx
  #    cookies['fileDownload'] = true
  #    send_file xfile[:path]
  #  end
  #  
  #end
  #
  #def checking_summary
  #
  #  case req_format
  #  when :json
  #    report = EvaluationReport::CheckingSummary.new(report_params)
  #    result = report.get_result
  #    render json: result
  #    
  #  when :xlsx
  #    report = EvaluationReport::CheckingSummary.new(report_params)
  #    xfile = report.to_xlsx
  #    cookies['fileDownload'] = true
  #    send_file xfile[:path]
  #  end
  #  
  #end
  
  protected
  
  def find_evaluation_forms(title)
    forms = EvaluationPlan.select(:id).not_deleted.find_by_title(title).all
    return forms
  end

  def date_range_params(date_range=params[:date_range])
    dates = date_range.split(" - ")
    ds = Date.parse(dates.first.strip) rescue Date.today
    dt = Date.parse(dates.last.strip) rescue Date.today
    return ds, dt
  end

  def find_user_id(name)
    users = User.select(:id).only_active.full_name_cont(name).all
    users = (users.map { |u| u.id }).concat([0])
    return users
  end

  def report_params
    prms = {}

    # view / period
    if params[:period_by].present?
      prms[:period_by] = params[:period_by].downcase
    end
    
    # evaluation form (id)
    if params[:form_id].present?
      prms[:form_id] = params[:form_id]
    end
    
    # evaluation form (name)
    if params[:form_name].present?
      if params[:form_name] =~ /^(\d+)$/
        prms[:form_id] = [params[:form_name].to_i]
      else
        forms = find_evaluation_forms(params[:form_name])
        prms[:form_id] = (forms.map { |f| f.id }).concat([0])     
      end
    end
    
    # show column by question|group_question
    if params[:column_by].present?
      prms[:column_by] = params[:column_by].to_s.downcase 
    end

    # show column by question|group_question
    if params[:row_by].present?
      prms[:row_by] = params[:row_by].to_s.downcase 
    end
    
    # calculation type
    if params[:calc].present?
      prms[:calc] = params[:calc].to_s.downcase
    end
    
    # call date range form:to
    if params[:date_range].present?
      dt, ds = date_range_params(params[:date_range])
      prms[:sdate] = dt
      prms[:edate] = ds
      prms[:sdatetime] = Time.parse(dt.strftime("%Y-%m-%d 00:00:00")).beginning_of_day
      prms[:edatetime] = Time.parse(ds.strftime("%Y-%m-%d 00:00:00")).end_of_day
    end

    if params[:agent_name].present?
      prms[:agent_name] = params[:agent_name]
      prms[:user_id] = find_user_id(params[:agent_name])
    end
    
    if params[:agent_id].present?
      prms[:user_id] = params[:agent_id]
    end
    
    if params[:qa_agent_name].present?
      prms[:qa_agent_name] = params[:qa_agent_name]  
    end
    
    if params[:group_name].present?
      prms[:group_name] = params[:group_name] 
    end
    
    if params[:template_id].present?
      prms[:template_id] = params[:template_id].to_i
    end

    if params[:call_type].present?
      prms[:call_type] = params[:call_type].to_s
    end
    
    return prms  
  end
  
  def attch_conditions_params
    pams = report_params
    pams[:sdate] = Date.today if pams[:sdate].nil?
    conds = {
      document_template_id_eq:   pams[:template_id],
      by_evaluation_logs: {
        evaluation_plan_id:     pams[:form_id],
        call_start_date:        pams[:sdate],
        call_end_date:          pams[:edate],
        agent_id:               pams[:user_id]
      }
    }
    return conds.remove_blank!   
  end
  
end
