class VoiceLogsController < ApplicationController
  
  before_action :authenticate_user!
  
  def info
    rs = {}
    selects = [:id, :voice_file_url]
    voice_log = VoiceLog.select(selects).where(id: voice_log_id).first
    unless voice_log.nil?
      voice_url = false
      if voice_log.have_url?
        tmp_file = voice_log.temporary_file
        unless tmp_file.nil?
          voice_url = tmp_file.url
        end
      end
      rs = {
        id: voice_log.id,
        voice_url: voice_url
      }
    end
    render json: rs
  end
  
  def export
    
    if params.has_key?(:file_id)
      
      file_id = params[:file_id]
      fpath = CallSearch.get_exported_file(file_id)
      
      if params.has_key?(:download)
        fname = File.basename(fpath)
        fname = ["CallHistory",Time.now.strftime("%Y%m%dT%H%M%S")].join("_") + File.extname(fname)
        send_file fpath, filename: fname
      else
        render json: { status: fpath }
      end
    
    else
      
      conds    = params[:search]
      paginate = params[:paginate]
      opts     = params[:opts]
      
      cs = CallSearch.new(conds)
      file_id = cs.file_id
      
      sch = Rufus::Scheduler.new
      sch.in '1s' do
        case opts[:ftype]
        when 'csv'
          cs.to_csv
        when 'xlsx'
          cs.to_xlsx
        end
      end
      
      render json: { file_id: file_id, file_type: opts[:ftype] }      
    
    end
  
  end
  
  def fav_call
    
    fav = params[:favourite]
    
    callf = CallFavourite.where({ voice_log_id: voice_log_id, user_id: current_user.id }).first
    if callf.nil? and fav == "true"
      callf = CallFavourite.new({ voice_log_id: voice_log_id, user_id: current_user.id })
      callf.save
    else
      unless callf.nil?
        callf.delete
      end
    end
    
    VoiceLogCounter.fav_count(voice_log_id, CallFavourite.where({ voice_log_id: voice_log_id}).count(0))
    
    render json: { updated: true }
  
  end
  
  def waveform
    svg_fname = false
    begin
      wf = Waveform.new(voice_log_id,{ width: params[:w], height: params[:h]})
      svg_fname = wf.to_svg
    rescue => e
      Rails.logger.error "Error while preparing waveform, #{e.message}"
    end
    if svg_fname.nil? or svg_fname == false
      svg_fname = File.join(Rails.root,'app/assets/images','not_available.svg')
    end
    send_file svg_fname, disposition: :inline
  end
  
  def keyword_log
    
  end
  
  def dsrresult_log
  
  end
  
  def trans_log
    
    voice_log = VoiceLog.where(id: voice_log_id).first    
    
    trans = []
    detected_info = {}
    dialogs = []
    dsr_stats = []
    detected_keywords = []
    cinfo = {}
    
    cinfo = voice_log.call_stats_info
    
    if can_doact?("voice_logs:transcriptions") and Settings.server.es.enable
      crrs = CallRecognitionResult.get_detail(voice_log_id)
      # transcription
      trans = CallTranscription.parse_raw_result(crrs.transcriptions)
      # dialogs
      dialogs = crrs.dialogs
      # stats
      dsr_stats = crrs.stats
      # keywords
      detected_keywords = crrs.detected_keywords
      trans = CallTranscription.highlight_keywords(trans, detected_keywords)
    end
    
    ## desktop application logs
    #desktop_result = {}
    #unless voice_log.nil?
    #  desktop_result = voice_log.desktop_activity
    #end
    #
    ## call events
    #events = CallAnnotation.only_call_events.by_voice_log(voice_log_id).all
    #events = CallAnnotation.result_log(events)
    #
    ## call reason
    #reasons = CallReason.by_voice_log(voice_log_id).all
    #reasons = CallReason.result_log(reasons)
    #
    ## merge 
    #trans = trans.concat(events)
    #trans = trans.sort { |a,b| a[:ssec] <=> b[:ssec] }
    
    render json: {
      callstats: cinfo,
      detected_keywords: detected_keywords,
      dsrstats: dsr_stats,
      trans: trans,
      topics: dialogs,      
      events:   [],
      reasons:  [],
      desktop:  [],
      additional_details: {},
      detected_info: []
    }

  end
  
  def update_transcription
    get_voice_log
    utrans = params[:transcription]
    utrans[:updated_by] = current_user.id
    utrans[:updated_at] = Time.now.to_formatted_s(:db)
    @voice_log.update_transcriptions(utrans)
    render json: {}
  end
  
  def send_mail
    
    m_params = mail_params
    
    users = User.find_email(m_params[:sender_id]).all
    sender = current_user
    
    CallMailer.send_call(users,m_params,sender).deliver
    
    render json: true
    
  end
  
  def download
    
    selects   = [:id, :voice_file_url, :start_time, :call_id]
    voice_log = VoiceLog.select(selects).where(id: voice_log_id).first
    output_format = params[:ftype]
    
    cookies['fileDownload'] = true
    
    unless voice_log.nil?
      t_file = voice_log.temporary_file.path
      t_file = FileConversion.audio_convert(output_format.to_sym, t_file)
      new_file_name = [voice_log.output_filename,output_format].join(".")
      send_file t_file, filename: new_file_name
    else
      render text: "file not found"
    end
    
  end
  
  def evaluate
    get_voice_log
    
    ev_params = params[:evaluation_form]
    ch_params = score_result_params(ev_params[:criteria])
    
    init_params = {
      evaluation_plan_id: ev_params[:form_id],
      revision_no: ev_params[:form_revision_no],
      voice_log_id: voice_log_id,
      user_id: ev_params[:agent_id],
      group_id: ev_params[:group_id],
      supervisor_id: ev_params[:supervisor_id],
      chief_id: ev_params[:chief_id],
      updated_by: current_user.id,
      comment: ev_params[:comment],
      reviewer: ev_params[:reviewer]
    }

    evaluation_log = EvaluationLog.new
    evaluation_log.do_init(init_params)
    evaluation_log.update_score(ch_params)
    evaluation_log.do_save

    # update agent id
    unless @voice_log.nil?
      unless @voice_log.agent_id == evaluation_log.user_id
        @voice_log.agent_id = evaluation_log.user_id
        @voice_log.save
      end
    end
    
    # update assignment
    atask = EvaluationAssignedTask.not_deleted.by_voice_logs(@voice_log.id).first
    if atask.nil?
      atask = {
        user_id: current_user.id,
        evaluation_task_id: 0,
        voice_log_id: @voice_log.id,
        assigned_by: current_user.id,
        assigned_at: Time.now.to_formatted_s(:db),
        flag: 'N',
        record_count: 1,
        total_duration: @voice_log.duration
      }
      atask = EvaluationAssignedTask.new(atask)
      atask.save
    end
    unless atask.nil?
      if atask.user_id == current_user.id
        atask.evaluated_by(current_user.id)
      else
        if atask.user_id.to_i == 0
          atask.evaluated_by(current_user.id)
        end
      end
      atask.save
    end
    
    render json: { updated: true }
  end
  
  def evaluated_info
    get_voice_log
    
    #
    # try to get default of user, group and leaders
    #
    
    user = User.where(id: @voice_log.agent_id).first
    unless user.nil?
      group = user.group_info({ evaluation_log: true })
    else
      user = User.new
      group = Group.new
    end
    leaders = []
    unless group.nil?
      group.leader_info.each do |l|
        leaders << {
          type: l.group_member_type.field_name,
          id: l.user_id,
          name: l.leader_info.display_name
        }
      end
    end
    
    #
    # try to get evaluation form and questions
    #
    
    ds_asst = []
    ds_evls = {}
    qa_user = nil
    ck_user = nil
    
    review_enable = false
    
    eform = EvaluationPlan.where(id: params[:form_id]).first
    unless eform.nil?
      
      # get evaluated result (manual)
      evaluation_log = EvaluationLog.find_log_by_call(@voice_log.id, eform.id).first
      unless evaluation_log.nil?
        
        # update agent, group and leaders
        unless user.id == evaluation_log.id
          user = User.where(id: evaluation_log.user_id).first
        end
        unless group.id == evaluation_log.group_id
          group = Group.where(id: evaluation_log.group_id).first
        end
        unless group.nil?
          leaders = []
          group.leader_info(nil, { evaluation_log: evaluation_log }).each do |l|
            leaders << {
              type: l.group_member_type.field_name,
              id: l.user_id,
              name: l.leader_info.display_name
            }
          end
        end
        
        if evaluation_log.evaluated_by.to_i > 0
          qa_user = User.where(id: evaluation_log.evaluated_by).first
        end
        
        if evaluation_log.checked_by.to_i > 0
          ck_user = User.where(id: evaluation_log.checked_by).first
        end
        
        # check authority of check
        review_enable = can_doact?("evaluations:recheck")
        if review_enable
          unless ck_user.nil?
            review_enable = (current_user.id == ck_user.id)
          else
            review_enable = Role.role_heigher(current_user.role_id, qa_user.role_id)
          end
        end
        
        ds_evls = {
          evaluation_log_id: evaluation_log.id,
          result: evaluation_log.score_logs,
          comment: evaluation_log.summary_comment,
          attachments: evaluation_log.attachments,
          reviewer: {
            checkable: review_enable,
            comment: evaluation_log.reviewer_comment,
            result: evaluation_log.checked_result.to_s
          }
        }
      else
        ds_evls = nil
      end
      
      # get auto assessment result
      asst_logs = nil
      if Settings.server.es.enable
        asst_logs = AutoAssessmentLog.get_assessment_logs(@voice_log.id)
      end
      unless asst_logs.nil?
        crits = eform.evaluation_criteria.only_criteria.not_deleted.all
        unless crits.empty?   
          found_asst = false
          crits.each do |crit|
            ast = AutoAssessmentLog.where(evaluation_plan_id: eform.id, voice_log_id: @voice_log.id, evaluation_question_id: crit.evaluation_question_id).first
            if ast.nil?
              ds_asst << {
                question_id: crit.evaluation_question_id,
                result_txt: "No",
                detected_info: {}
              }
            else
              ast.set_asst_logs(asst_logs)
              found_asst = true
              ds_asst << {
                question_id: crit.evaluation_question_id,
                result_txt: ast.result_label,
                detected_info: ast.get_detected_info
              }
            end
          end
          ds_asst = [] if found_asst == false
        end  
      end
    
      # end of form.nil?
    end
    
    # check form enable
    # form_allow = EvaluationAssignedTask.assigned_to?(@voice_log.id, current_user.id)
    form_allow = false
    unless qa_user.nil?
      if qa_user.id == current_user.id or Role.role_heigher(current_user.role_id, qa_user.role_id)
        form_allow = true
      end
      unless ck_user.nil?
        if review_enable == false
          form_allow = false
        end
      end
    else
      form_allow = true
    end
    
    gp_id = (group.nil? ? nil : group.id)
    gp_name = (group.nil? ? nil : group.short_name)

    # return data
    ds = {
      voice_log_id: @voice_log.id,
      agent: {
        id: user.id, name: user.display_name },
      group: { 
        id: gp_id, name: gp_name },
      leaders: leaders,
      asst: ds_asst,
      evls: ds_evls,
      form_enable: form_allow,
      review_enable: review_enable
    }
    Rails.logger.debug "Evaluation Permission flag: F=#{form_allow},C=#{review_enable}"
    
    render json: ds
  end
  
  def evaluated_score
    
    ret = []
    
    logs = EvaluationLog.find_logs({voice_log_id: voice_log_id})
    logs.each do |log|
      plan = EvaluationPlan.where(id: log.evaluation_plan_id).first
      ret << {
        name: plan.name,
        total_score: StringFormat.score_fmt(log.total_score),
        weighted_score: StringFormat.score_fmt(log.weighted_score)
      }
    end
    
    render json: ret
  
  end
    
  def remove_evaluation
    evaluation_log = EvaluationLog.find_log_by_call(voice_log_id, params[:form_id]).first
    unless evaluation_log.nil?
      evaluation_log.updated_by = current_user.id
      evaluation_log.do_delete
      evaluation_log.save
    end
    render json: { deleted: true }  
  end

  def call_tagging
    if params[:code].present? and params[:result].present?
      tag_id = params[:code].to_i
      checked = params[:result] == "true"
      tag = Tagging.find_by_voice_log(voice_log_id).where(tag_id: tag_id).first
      if tag.nil? and checked
        tag = Tagging.new(tag_id: tag_id, tagged_id: voice_log_id)
        tag.save
      elsif not tag.nil? and not checked 
        tag.delete
        tag = nil
      end
    end
    
    data = []
    tagged_id = Tagging.select(:tag_id).find_by_voice_log(voice_log_id).all
    unless tagged_id.empty?
      tags = Tag.where(id: tagged_id).all
      tags.each do |tag|
        data << { id: tag.id, title: tag.name, text: tag.name }
      end
    end
    render json: data
  end
  
  def call_type
    result = []
    
    if params[:code].present? and params[:result].present?
      
      category_id = params[:code].to_i
      checked     = params[:result] == "true"
      
      category = CallCategory.find_id(category_id)
      unless category.nil?
        cc = CallClassification.find_category(voice_log_id, category.id).first
        if cc.nil?
          if checked
            cc = {
              voice_log_id: voice_log_id,
              call_category_id: category.id,
              updated_by: current_user.id
            }
            cc = CallClassification.new(cc)
            cc.save
          end
        else
          if not checked
            cc.do_delete
          else
            if cc.undo_delete
              cc.updated_by = current_user.id
            end
          end
          cc.save
        end
      end
      
      CallClassification.update_to_es(voice_log_id)
    end

    # current info
    result = []
    CallCategory.not_deleted.all.each do |c|
      result << {
        code: c.id,
        result: false,
        title: c.title
      }
    end

    cc = CallClassification.not_deleted.find_category(voice_log_id).all
    cc.each do |c|
      result.each { |a| a[:result] = true if c.call_category_id == a[:code] }  
    end
    
    render json: result
    
  end

  def evaluation_more_info
    
    hist_log = []
    
    vl_log = EvaluationCall.select(:evaluation_log_id).where(voice_log_id: voice_log_id)
    el_log = EvaluationLog.where(id: vl_log).order(updated_at: :desc).all
    
    el_log.each do |el|
      hist_log << {
        at_time: el.updated_at.to_formatted_s(:web),
        updated_by: User.where(id: el.updated_by).first.display_name
      }
    end
    
    render json: { hist: hist_log }
    
  end
  
  def trans_file
    ctr = CallTranscriptionReport.new(voice_log_id)
    out_file = ctr.to_file
    cookies['fileDownload'] = true
    send_file out_file
  end

  def assessment_info    
  end
  
  def ana_result_logs
    
    msg_logs = []
    mls = MessageLog.where(voice_log_id: voice_log_id).only_recommendation.order(:created_at).all
    unless mls.empty?
      mls.each_with_index do |ml,i|
        msg_logs << {
          no: i+1,
          speech_at: ml.speech_at_t3,
          text: ml.detected_sentence,
          faq_question: ml.faq_info[:question],
          faq_answer: ml.faq_info[:answers_c]
        }
      end
    end
    
    render json: {
      msg_logs: msg_logs
    }
  end
  
  private
  
  def voice_log_id
    params[:id]
  end

  def get_voice_log
    @voice_log = VoiceLog.where(id: voice_log_id).first
    if @voice_log.nil?
      @voice_log = VoiceLogToday.where(id: voice_log_id).first
    end
  end
  
  def mail_params
    return {
      sender_id: params[:to],
      message: params[:msg],
      subject: params[:subj],
      voice_log_id: voice_log_id,
      start_sec: params[:stsec].to_s,
      attach_file: params[:attach_file]
    }
  end
  
  def score_result_params(pam)
    # hash to array
    quests = pam.map { |k, v| v }
    quests.each do |q|
      if q["result"].present?
        q["result"] = q["result"].map { |k,v| v }
      else
        # set default value = []
        q["result"] = []
      end
    end
    return quests
  end

  def get_age(v)
    if v.blank?
      return nil
    else
      begin
        y = to_datefmt(v).split("-").last.to_i
        if y > 0
          if y <= 2000
            return (Date.today.year - y)
          else
            return (Date.today.year - (y - 543))
          end
        else
          return nil
        end      
      rescue => e
        return nil
      end
    end
  end
  
  def to_datefmt(date)
    d = sprintf("%02d",date["day"].to_i)
    m = sprintf("%02d",date["month"].to_i)
    y = sprintf("%04d",date["year"].to_i)
    return [d,m,y].join("-")
  end
  
end
