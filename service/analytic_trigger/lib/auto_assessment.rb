module AnalyticTrigger
  class AutoAssessment
    
    def self.update(task, opts={})
      xtask = new(task, opts)
      return xtask.update
    end
    
    def initialize(task, opts={})
      @task = task
      @opts = opts
    end
    
    def update
      if enable? and process_record? and ready?
        @forms.each do |form_id, form|
          log :info, "trying to process '#{form[:name]} #{form[:form_id]}'"
          data = AnaTaskResult.get_result(pass_options(form))
          data.messages.each do |msg|
            log :info, msg
          end
          unless data.raw_result.nil?
            update_result(form, parse_result(form, data.raw_result))
          end
        end
      end
    end
    
    private
    
    def create_asst_comment(result)
      ast_comment = nil
      if not result["debug_engine_result"].blank?
        ast_comment = []
        result["debug_engine_result"].each do |dr|
          if dr["flag"] == false
            ast_comment << dr["options"]["reject_message"]
          else
            ast_comment << dr["options"]["accept_message"]
          end
        end
        ast_comment = ast_comment.join(", ")
      end
      return ast_comment
    end
    
    def mapped_question_result(result)
      question_id = result["question_id"].to_i
      question = result["question_name"]
      
      if question_id > 0
        answer_value = ((result["pass"] == true) ? 'yes' : 'no')
        answer_value = result["mapped"]
        
        dblog = {
          evaluation_question_id: question_id,
          evaluation_answer_id: 0,
          result: answer_value,
          flag: ""
        }
        eslog = {
          evaluation_question_id: question_id,
          comment: create_asst_comment(result),
          debug_result: result["debug_result"]
        }
        
        return dblog, eslog
      end
      return nil, nil
    end
    
    def parse_result(form, raw)
      data = {
        logs: [], detail_logs: []
      }
      
      if raw.is_a?(Array)
        raw.each do |result|
          dblog, eslog = mapped_question_result(result)
          unless dblog.nil?
            dblog[:voice_log_id] = @task.voice_log.id
            dblog[:evaluation_plan_id] = form[:form_id].to_i
            eslog[:evaluation_plan_id] = form[:form_id].to_i
            
            data[:logs] << dblog
            data[:detail_logs] << eslog
            log :debug, "question #{dblog[:evaluation_question_id]}: #{dblog[:result]}"
          end
        end
      end
      
      return data
    end
        
    def mapped_name_question(name)
      case name.to_s
      when "acs_greeting"
        return 80
      when "acs_ending"
        return 81
      end
    end
    
    def update_result(form, data)
      # update db
      log :info, "trying update result to db/logs"
      begin
        AutoAssessmentLog.where(voice_log_id: @task.voice_log.id, evaluation_plan_id: form[:form_id]).delete_all
        data[:logs].each do |log|
          asst_log = AutoAssessmentLog.new(log)
          asst_log.save
        end
      rescue => e
        log :error, e.message
      end
      
      # update es
      log :info, "trying update result to es/logs"
      begin
        ves = ElsClient::VoiceLogDocument.new(@task.voice_log.id)
        if ves.created?
          ves.update_asst_logs(data[:detail_logs])
        end
      rescue => e
        log :error, e.message
      end
    end
    
    def pass_options(form)
      options = {
        url: Settings.server.analytic.assessment.url,
        timeout: Settings.server.analytic.assessment.timeout
      }
      options[:params] = {
        voice_log_ids: [@task.voice_log.id],
        question_mapping: form[:questions]
      }
      options[:url] = Settings.server.analytic.assessment.url
      return options
    end
    
    def ready?
      return found_matched_forms
    end
    
    def process_record?
      # to validate basic information
      # that nessessary for perform the process
      
      # skip short call duration
      if @task.voice_log.duration.to_i <= 1
        log :info, "skipped, duration too short."
        return false
      end
      
      # skip private call
      if @task.voice_log.private_call?
        log :info, "skipped, private call"
        return false
      end
      
      return true
    end
    
    def found_matched_forms
      @forms = {}
      forms = EvaluationPlan.only_auto_assessment.all
      forms.each do |form|
        if form.matched_asst_form?(@task.voice_log)
          @forms["#{form.id}"] = { form_id: form.id, name: form.name }
          @forms["#{form.id}"][:questions] = found_questions(form.id)
        end
      end
      return (not @forms.empty?)
    end
    
    def found_questions(form_id)
      out_questions = []
      sql = "SELECT evaluation_question_id FROM auto_assessment_criteria WHERE evaluation_plan_id = #{form_id}"
      result = SqlClient.select_all(sql)
      unless result.empty?
        q_ids = result.map { |r| r["evaluation_question_id"] }
        questions = EvaluationQuestion.where(id: q_ids).where.not(flag: 'D').all
        questions.each do |qu|
          ans = EvaluationAnswer.where(evaluation_question_id: qu.id).order(revision_no: :desc).first
          unless ans.nil?
            ana = ans.ana_settings
            params = {
              #engine: ana["engine_name"],
              #name: ana["rule_name"]
            }
            #if not ana["parameters"].nil? and ana["parameters"].is_a?(Hash)
            #  params = params.merge(ana["parameters"])
            #end
            out_questions << {
              question_id: qu.id,
              parameters: params
            }
          end
        end
      end
      return out_questions
    end
    
    def log(type, message)
      @task.logkls :asst, type, message
    end
    
    def enable?
      return Settings.server.analytic.assessment.enable
    end
    
  end
end