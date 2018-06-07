class EvaluationLog < ActiveRecord::Base
  
  # flag: checked result
  FLAG_CORRECT = 'C'
  FLAG_WRONG   = 'W'
  
  has_many    :evaluation_score_logs
  has_many    :evaluation_comments
  has_many    :evaluation_calls
  has_many    :evaluation_doc_attachments
  belongs_to  :evaluation_plan
  belongs_to  :user
  belongs_to  :group
  
  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)  
  }
  
  scope :find_log_by_call, ->(voice_log_id, form_id){
    call_log = EvaluationCall.find_evaluated_call(form_id, voice_log_id).order(id: :desc).first
    unless call_log.nil?
      where(id: call_log.evaluation_log_id).not_deleted
    else
      where(id: 0)
    end
  }

  scope :ndays_ago, ->(days){
    where("evaluation_logs.evaluated_at >= ?", Date.today - days)  
  }
  
  def self.revision_info(voice_log_id, form_id)
    log = find_log_by_call(voice_log_id, form_id).not_deleted.first
    unless log.nil?
      return log.revision_info(form_id)
    end
    return nil
  end
  
  def evaluation_form
    self.evaluation_plan   
  end
  
  def revision_info(plan_id)
    # get all revision no for form and all criteria
    revs = {
      form_revision: self.revision_no,
      question_revision: {}
    }
    quests = self.evaluation_score_logs.select([:evaluation_question_id, :revision_no]).only_question.all
    quests.each do |q|
      revs[:question_revision][q.evaluation_question_id.to_s] = q.revision_no
    end
    return revs
  end
  
  def total_weighted_score
    return calc_weighted_score  
  end
  
  def deleted?
    return (self.flag == DB_DELETED_FLAG)
  end
  
  def agent_info
    if self.user.nil?
      return User.new
    end
    return self.user
  end
  
  def group_info
    if self.group.nil?
      return Group.new
    else
      return self.group
    end
  end
  
  def score_info
    sc = {
      max: 0,
      total: 0,
      average: 0,
      weighted: 0,
      grade: "N/A"
    }
    self.evaluation_score_logs.all.each do |x|
      sc[:max] += x.max_score
      sc[:total] += x.actual_score
      sc[:average] += x.actual_score/x.max_score*100.0
    end
    sc[:weighted] = sc[:total]/sc[:max]*100
    sc[:grade] = EvaluationPlan.get_grade(sc[:weighted], self.evaluation_plan_id)
    return sc
  end
  
  def all_comments
    cmts = {}
    self.evaluation_comments.all.each do |cm|
      case true
      when cm.written_by_evaluator?
        cmts[:by_evaluator] = cm.comment
      when cm.writted_by_reviewer?
        cmts[:by_reviewer] = cm.comment
      end
    end
    return cmts
  end
  
  def evaluator_info
    User.where(id: self.evaluated_by).first   
  end
  
  #def self.find_log(ds)
  #  
  #  # by form
  #  evc = EvaluationCall.find_evaluated_call(ds[:form_id],ds[:voice_log_id]).order(id: :desc).first
  #  evl_id = (evc.nil? ? 0 : evc.evaluation_log_id)
  #  
  #  return EvaluationLog.not_deleted.where({ id: evl_id }).first
  #
  #end
  #
  #def self.find_logs(ds)
  #  # all form
  #  
  #  evc = EvaluationCall.where(voice_log_id: ds[:voice_log_id]).all
  #  return EvaluationLog.not_deleted.where({ id: evc.map { |e| e.evaluation_log_id } }).all
  #
  #
  
  def do_init(init_params)
    pam = init_params
    # fine old log
    @old_log.nil?
    @call_log = EvaluationCall.find_evaluated_call(pam[:evaluation_plan_id], pam[:voice_log_id]).first
    @atchs = nil
    unless @call_log.nil?
      @old_log = EvaluationLog.where(id: @call_log.evaluation_log_id).first
      @atchs = EvaluationDocAttachment.where(evaluation_log_id: @old_log.id).all
    else
      @call_log = EvaluationCall.new
      @call_log.evaluation_plan_id = pam[:evaluation_plan_id]
      @call_log.voice_log_id = pam[:voice_log_id]
      @call_log.update_call_info
    end
    # comment
    unless pam[:comment].blank?
      @cmm_log = EvaluationComment.new_summary_comment
      @cmm_log.comment = pam[:comment]
    end

    # update field
    self.evaluation_plan_id = pam[:evaluation_plan_id]
    self.revision_no = pam[:revision_no]
    if not @old_log.nil? and not @old_log.deleted?
      @old_log.ref_log_id = @old_log.get_ref_id
      self.attributes = @old_log.attributes
      self.flag = ""
      self.id = nil
    else
      self.ref_log_id = 0
      self.evaluated_by = pam[:updated_by]
      self.evaluated_at = Time.now
    end
    self.user_id = pam[:user_id].to_i
    self.group_id = pam[:group_id].to_i
    self.supervisor_id = pam[:supervisor_id].to_i
    self.chief_id = pam[:chief_id].to_i
    self.updated_by = pam[:updated_by].to_i
    
    # reviewer
    unless pam[:reviewer].blank?
      if pam[:reviewer][:result].length > 0
        @rew_log = EvaluationComment.new_reviewer_comment
        @rew_log.comment = pam[:reviewer][:comment]
        if pam[:reviewer][:update_by_reviewer] == "yes"
          self.checked_by = pam[:updated_by]
          self.checked_at = Time.now
          self.checked_result = pam[:reviewer][:result]
        end
      else
        self.checked_by = nil
        self.checked_at = nil
      end
    end
    
  end
  
  def do_save
    # save log
    save
    # mark delete old one
    if defined? @old_log
      @old_log.do_delete
      @old_log.save
    end
    # update call log
    @call_log.evaluation_log_id = self.id
    @call_log.save
    # update comment
    if defined? @cmm_log
      @cmm_log.evaluation_log_id = self.id
      @cmm_log.save
    end
    # update score log
    @sc_logs.each do |sc|
      sc.evaluation_log_id = self.id
      sc.save
    end
    if defined? @rew_log
      @rew_log.evaluation_log_id = self.id
      @rew_log.save
    end
    # update attach
    if defined? @atchs and not @atchs.blank?
      @atchs.each do |atch|
        atch.evaluation_log_id = self.id
        atch.save
      end
    end
    # calc total score
    calc_score
  end
  
  def do_delete  
    self.flag = DB_DELETED_FLAG
  end
  
  def update_score(sc_params)
    @sc_logs = []
    sc_params.each do |sc_pam|
      qu = EvaluationQuestion.where(id: sc_pam[:question_id]).first
      tt_score = 0
      sc_pam["result"].each do |rs|
        if rs["deduction"].present? and rs["score"].to_f < 0
          if rs["deduction"] == "uncheck"
            tt_score += rs["score"].to_f.abs
          end
        else
          tt_score += rs["score"].to_f
        end
      end
      esl = {
        evaluation_log_id: 0,
        evaluation_question_id: qu.id,
        question_group_id: qu.question_group_id,
        max_score: qu.max_score,
        actual_score: tt_score,
        answer: sc_pam["result"],
        comment: sc_pam["comment"],
        revision_no: sc_pam["revision_no"]
      }
      @sc_logs << EvaluationScoreLog.new(esl)
    end
  end
  
  def calc_score
    slc = ScoreLogCalculation.new(self)
    slc.calc_score_and_save
  end
  
  def score_logs
    logs = self.evaluation_score_logs.only_question.all
    return logs.map { |l|  { question_id: l.evaluation_question_id, result: l.filtered_answer, comment: l.comment } }
  end
  
  def summary_comment
    cmm = self.evaluation_comments.for_evaluation.first
    unless cmm.nil?
      return cmm.comment
    end
    return nil
  end
  
  def reviewer_comment
    cmm = self.evaluation_comments.for_reviewer.first
    unless cmm.nil?
      return cmm.comment
    end
    return nil
  end
  
  def attachments
    # check list of attachments
    @attachments = []
    form = self.evaluation_form
    unless form.nil?
      acts = form.rules
      unless acts.blank?
        acts.each do |act|
          next unless act["action"] == "raise_document"
          next unless matched_template_condition?(act["condition"])
          doc = DocumentTemplate.where(id: act["target_id"]).first
          @attachments << {
            id: doc.id,
            title: doc.title,
            mapped_fields: doc.mapped_fields,
            evaluation_log_id: self.id
          }
        end
      end
    end
    return @attachments
  end

  def get_ref_id
    if self.ref_log_id.to_i > 0
      return self.ref_log_id
    end
    return self.id
  end
  
  private
  
  def matched_template_condition?(condition_str)
    unless @evresult
      @evresult = {}
      sql = []
      sql << "SELECT s.evaluation_question_id,s.actual_score, q.code_name"
      sql << "FROM evaluation_score_logs s"
      sql << "LEFT JOIN evaluation_questions q"
      sql << "ON s.evaluation_question_id = q.id"
      sql << "WHERE s.evaluation_log_id = #{self.id}"
      result = ActiveRecord::Base.connection.select_all(sql.join(" "))
      result.each do |rs|
        next if rs["code_name"].blank?
        @evresult[rs["code_name"]] = {
          value: rs["actual_score"].to_i
        }
      end
    end
    new_cond = nil
    @evresult.each do |k,v|
      new_cond = condition_str.gsub(k,v[:value].to_s)
      unless new_cond == condition_str
        new_cond = new_cond.gsub("=","==")
        Rails.logger.debug "DocumentTemplate, Found valid condition #{condition_str} => [#{k}, #{v}] => #{new_cond}"
        break
      else
        new_cond = nil
      end
    end
    begin
      unless new_cond.nil?
        rs = eval(new_cond)
        Rails.logger.debug "DocumentTemplate, Found valid condition #{condition_str} => #{new_cond} [#{rs}]"
        return rs
      end
    rescue => e
      Rails.logger.error "DocumentTemplate, error check #{e.message}"
    end
    return false
  end
    
  def calc_weighted_score
    tt_w_score = 0
    sql = []
    #sql << "SELECT a.id, a.evaluation_plan_id, a.revision_no, a.question_group_id, a.weighted_score, c.weighted_score as max_weighted_score"
    #sql << "FROM" 
    #sql << "(SELECT l.id, l.evaluation_plan_id, l.revision_no, s.question_group_id, s.weighted_score, s.actual_score, s.max_score"
    #sql << "FROM evaluation_logs l JOIN evaluation_score_logs s ON l.id = s.evaluation_log_id"
    #sql << "WHERE s.evaluation_question_id = 0 AND l.flag <> 'D'"
    #sql << "AND l.id = #{self.id} AND l.evaluation_plan_id = #{self.evaluation_plan_id}) a"
    #sql << "LEFT JOIN evaluation_criteria c ON a.evaluation_plan_id = c.evaluation_plan_id"
    #sql << "AND a.question_group_id = c.question_group_id"
    #sql << "AND a.revision_no = c.revision_no"
    #sql << "WHERE item_type = 'category'"
    #sql << "AND c.evaluation_plan_id = #{self.evaluation_plan_id}"
    sql << "SELECT *"
    sql << "FROM evaluation_score_logs s"
    sql << "WHERE s.evaluation_log_id = #{self.id}"
    sql = sql.join(" ")
    result = ActiveRecord::Base.connection.select_all(sql)
    result.each do |r|
      #w_score = r["weighted_score"].to_f * r["max_weighted_score"].to_f / 100.0
      tt_w_score += r["weighted_score"].to_f
    end
    return tt_w_score.round(2)
  end
  
  # end class
end
