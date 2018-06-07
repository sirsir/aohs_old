class EvaluationDocAttachment < ActiveRecord::Base
  
  belongs_to  :document_template
  belongs_to  :evaluation_logs
  
  serialize :doc_data, JSON
  
  scope :by_evaluation_log, ->(id){
    where({ evaluation_log_id: id })  
  }
  
  scope :by_evaluation_logs, ->(*cond){
    sql = "SELECT 1 FROM evaluation_logs l JOIN evaluation_calls c "
    sql << "ON l.id = c.evaluation_log_id "
    sql << "WHERE l.flag <> 'D' AND #{self.table_name}.evaluation_log_id = l.id "
    cond.each do |cd|
      if cd.first == "call_start_date"
        sql << "AND c.call_date >= '#{cd.last.strftime("%Y-%m-%d")}'"
      end
      if cd.first == "call_end_date"
        sql << "AND c.call_date <= '#{cd.last.strftime("%Y-%m-%d")}'"
      end
      if cd.first == "evaluation_plan_id"
        sql << "AND l.evaluation_plan_id IN (#{cd.last.join(",")})"
      end
      if cd.first == "agent_id"
        sql << "AND l.user_id IN (#{cd.last.join(",")})"
      end
    end
    where("EXISTS (#{sql})")
  }
  
  scope :not_deleted, ->{
    where.not({ flag: DB_DELETED_FLAG })  
  }
  
  def do_init(params={})
    @template = params[:template]
    @mapped_fields = @template.mapped_fields
    set_field_info
  end
  
  def mapped_fields
    return @mapped_fields  
  end
  
  def mapped_fields_for_render
    ofields = {}
    unless self.doc_data.nil?
      self.doc_data.each do |fd|
        ofields[fd["name"]] = fd["value"]
      end
    end
    return ofields
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG  
  end
  
  def filename(prefix="")
    calllog = EvaluationCall.where(evaluation_log_id: self.evaluation_log_id).first
    unless calllog.nil?
      return "#{prefix}_#{calllog.start_time_v2}"
    else
      return "#{prefix}_"
    end
  end
  
  private
  
  def set_field_info
    evaluation_log = EvaluationLog.where({ id: self.evaluation_log_id }).first
    agent = evaluation_log.agent_info
    group = evaluation_log.group_info
    leader_info = leader_fields(group, evaluation_log)
    evaluator = evaluation_log.evaluator_info    
    evaluation_call = EvaluationCall.where({ evaluation_log_id: self.evaluation_log_id }).first
    voice_log = VoiceLog.where(id: evaluation_call.voice_log_id).first
    evaluated_info = get_evaluated_result
    comments = evaluation_log.all_comments
    score_info = evaluation_log.score_info
    
    @mapped_fields.each do |field|
      mapped_field = field["name"].gsub(/\[|\]/,"")
      value = nil
      readonly = false
      
      case mapped_field
      # agent detail
      when "AGENT_NAME"
        value = agent.display_name
      when "GROUP_NAME", "TEAM_NAME"
        value = group.display_name
      when "EMPLOYEE_ID"
        value = agent.employee_id
      when "CITIZEN_ID"
        value = agent.citizen_id
      when "AGENT_ROLE", "ROLE_NAME"
        value = agent.role_name
        
      # call detail
      when "CALL_TIME"
        value = voice_log.start_time.strftime("%H:%M:%S")
      when "CALL_DATE"
        value = voice_log.start_time.strftime("%Y-%m-%d") 
      when "CALL_DATETIME", "CALL_START_TIME"
        value = voice_log.start_time.to_formatted_s(:web) 
      when "CALL_LENGTH", "CALL_DURATION"
        value = StringFormat.format_sec(voice_log.duration.to_i) 
      when "CALLER_NO", "ANI"
        value = StringFormat.format_phone(voice_log.ani)
      when "DIALED_NO", "DNIS"
        value = StringFormat.format_phone(voice_log.dnis)
      when "EXTENSION_NO", "EXTENSION"
        value = StringFormat.format_phone(voice_log.extension)
      when "CALL_DIRECTION"
        value = voice_log.call_direction_name
      when "AGENT_PHONE_NO"
        value = voice_log.agent_phone_no
      when "CUSTOMER_PHONE_NO"
        value = voice_log.customer_phone_no
      
      # customer detail
      when "CUSTOMER_NAME"
        value = voice_log.customer_name
        
      # evaluation detail
      when "SUMMARY_COMMENT"
        value = comments[:by_evaluator].to_s
      when "QUESTION_COMMENTS"
        unless evaluated_info["all_comments"].blank?
          value = evaluated_info["all_comments"].join(" \r\n")
        end
      when "GRADE"
        value = score_info[:grade]
      when "EVALUATED_BY"
        value = evaluator.display_name
      when "EVALUATED_TIME"
        value = evaluation_log.evaluated_at.to_formatted_s(:web)
      when "SUPERVISOR_NAME"
        value = leader_info["SUPERVISOR_NAME"]
      when "CHIEF_NAME"
        value = leader_info["CHIEF_NAME"]

      # others
      when "TIME_STAMP", "TIMESTAMP"
        value = self.updated_at.to_formatted_s(:web) rescue "-"
      end
      
      # definded field
      if value.nil?
        if not evaluated_info[mapped_field].nil?
          value = evaluated_info[mapped_field]
        elsif not leader_info[mapped_field].nil?
          value = leader_info[mapped_field]
        end
      end
      
      field["readonly"] = (!value.blank?)
      field["value"] = value
      
      # load existing field
      if value.blank? and not existing_fields[mapped_field].nil?
        field["value"] = existing_fields[mapped_field]
      end

      value = "" if value.nil?
    end # end mapped field

  end
  
  def get_evaluated_result
    sql = []
    sql << "SELECT s.evaluation_question_id, s.actual_score, s.comment, s.answer, q.code_name"
    sql << "FROM evaluation_score_logs s"
    sql << "LEFT JOIN evaluation_questions q"
    sql << "ON s.evaluation_question_id = q.id"
    sql << "WHERE s.evaluation_log_id = #{self.evaluation_log_id}"
    result = ActiveRecord::Base.connection.select_all(sql.join(" "))
    fields = {
      "all_comments" => []
    }
    result.each do |rs|
      # for all
      unless rs["comment"].blank?
        fields["all_comments"] << rs["comment"].to_s
      end
      # for each
      next if rs["code_name"].to_s.length <= 0
      # [<CODE>]
      fields[rs["code_name"]] = ((JSON.parse(rs["answer"]).select { |x| x["deduction"].nil? or x["deduction"] == "checked" }).map { |x| x["title"] }).join(",")
      # [<CODE>_COMMENT]
      fields[rs["code_name"]+"_COMMENT"] = rs["comment"] unless rs["comment"].blank?
    end
    return fields
  end
  
  def leader_fields(group, evaluation_log=nil)
    fields = {}
    GroupMemberType.all_types.each do |leader_type|
      begin
        lkey = leader_type.display_name.upcase.gsub(" ","_")
        unless evaluation_log.nil?
          lead_id = 0
          case leader_type.member_type
          when "L"
            lead_id = evaluation_log.supervisor_id
          when "C"
            lead_id = evaluation_log.chief_id
          end
          lead = User.where(id: lead_id).first
          unless lead.nil?
            fields["#{lkey}_NAME"] = lead.display_name
          end
        else
          fields["#{lkey}_NAME"] = group.leader_info(leader_type.member_type).leader_info.display_name
        end
      rescue => e
        STDERR.puts e.message
      end
    end
    return fields
  end
  
  def existing_fields
    fields = {}
    unless self.doc_data.nil?
      self.doc_data.each do |f|
        fields[f["name"].gsub(/\[|\]/,"")] = f["value"]
      end
    end
    return fields
  end

  def self.ransackable_scopes(auth_object = nil)
    %i(by_evaluation_logs)
  end
  
end
