class EvaluationPlan < ActiveRecord::Base
  
  has_paper_trail

  strip_attributes  allow_empty: true,
                    collapse_spaces: true
  
  # rule data structure
  # rule_type: [<list>]
  serialize :rules, JSON
  serialize :call_settings, JSON
  
  default_value_for :revision_no,  1
  default_value_for :asst_flag, ""
  
  after_initialize :set_default
  
  has_many    :evaluation_criteria
  has_many    :evaluation_grades, foreign_key: 'evaluation_grade_setting_id'
  has_many    :evaluation_staffs
  has_many    :evaluation_tasks
  belongs_to  :evaluation_grade_setting
  
  validates   :name,
                uniqueness: {
                  case_sensitive: false
                },
                presence: true,
                length: {
                  minimum: 3,
                  maximum: 100
                }

  validates   :description,
                allow_blank: true,
                allow_nil: true,   
                length: {
                  minimum: 3,
                  maximum: 200
                }
                
  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)  
  }
  
  scope :only_active, ->{
    where.not(flag: [DB_DELETED_FLAG, 'S'])
  }
  
  scope :at_revision, ->(n){
    where(revision_no: n)  
  }

  scope :only_auto_assessment, ->{
    not_deleted.where(asst_flag: "Y")
  }

  scope :find_by_title, ->(t){
    where(["name LIKE ?", "%#{t}%"])
  }
  
  scope :order_by, ->(p) {  
    incs      = []
    order_str = resolve_column_name(p)
    incs << :evaluation_grade_setting if order_str.match(/(evaluation_grade_settings)/)
    includes(incs).order(order_str)
  }

  def self.get_grade(score, evaluation_plan_id)
    sql = "SELECT * FROM evaluation_grade_current "
    sql << "WHERE #{score.to_i} BETWEEN lower_bound AND upper_bound AND evaluation_plan_id = #{evaluation_plan_id} "
    sql << "LIMIT 1"
    rs = ActiveRecord::Base.connection.select_all(sql)
    if rs.empty?
      return "Unk."
    else
      return rs.first["name"]
    end
  end
  
  def self.get_category_from_params(data)
    # to get all categories from asst params
    # multiple array to single array
    cates = []
    if data["call_category"].present?
      data["call_category"].each do |cate|
        cates = cates.concat(cate.map { |c| c.to_i })
      end
    end
    return cates
  end
  
  def self.find_plans_for_call(voice_log_id, conds={})
    # To find related evaluation form for specific call
    plans = []
    last_form_id = 0
    
    vl = VoiceLog.where(id: voice_log_id).first
    unless vl.nil?
      last_form_id = vl.get_last_evaluated_form.to_i
    end
    
    all_plans = not_deleted.all
    all_plans.each do |plan|
      next if plan.new?
      
      is_matched, matched_score = plan.matched_asst_form(vl)
      matched_score += 100 if last_form_id == plan.id
      plans << {
        id: plan.id,
        title: plan.title,
        locked_revision_no: plan.revision_no.to_i,
        selected: is_matched,
        matched_score: matched_score
      }
    end
    
    # updated selected (current)
    begin
      plans = plans.sort { |a, b| a[:matched_score] <=> b[:matched_score] }
      max_score = plans.reverse.first[:matched_score]
      plans.each { |plan| plan[:selected] = plan[:matched_score] >= max_score }
    rescue => e
    end
    
    # sort
    plans = plans.sort { |a, b| a[:title] <=> b[:title] }
    
    return plans
  end
  
  def self.rule_options
    options = []
    # raise documents
    # [[<group>,[<option{}>]]]
    raise_options = []
    DocumentTemplate.not_deleted.order_by_default.each do |doc|
      raise_options << { text: "Raise '#{doc.title}'", value: ["raise_document",doc.id].join("||") }
    end
    options << ["Raise document",raise_options]
    return options
  end
  
  def self.evaluate_type_code(name)
    return (EVALUATE_TYPES.select { |k,v| v.include?(name.to_s.downcase) }).keys.first
  end
  
  def title
    self.name
  end
  
  def status_title
    get_form_status
  end
  
  def grade_title
    self.evaluation_grade_setting.title rescue ""
  end
  
  def auto_assessment_status_name
    return (self.asst_flag == "Y" ? "Enabled" : "Disabled")
  end
  
  def suspended?
    ['D','S'].include?(self.flag)
  end
  
  def new?
    return (self.evaluation_criteria.not_deleted.count(0) <= 0)
  end
  
  def active?
    !suspended?
  end
  
  def deleted?
    ['D'].include?(self.flag)  
  end

  def can_delete?
    return true
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
  end

  def matched_asst_form?(voice_log)
    is_matched, score = matched_condition_score(voice_log)
    return is_matched
  end
  
  def matched_asst_form(voice_log)
    return matched_condition_score(voice_log)
  end
  
  def total_weighted_score
    w_score = self.evaluation_criteria.only_category.not_deleted.sum(:weighted_score).to_i
    return w_score
  end
  
  def question_revision_no
    # get last revision number.
    self.evaluation_criteria.max_revision_no.to_i
  end
  
  def next_revision_no
    # next revision no
    question_revision_no + 1
  end
  
  def update_criteria(quests)
    unless criteria_changed?(quests)
      # return if data does not have any update/change
    else
      # update criteria to table for refer to questions
      # mark old delete to old record and create new.
      rev_no = next_revision_no
      # each criteria group
      quests.each do |quest_group|
        ec_group = {
          evaluation_plan_id: self.id,
          name: quest_group[:title],
          item_type: quest_group[:type],
          weighted_score: quest_group[:weighted_score],
          evaluation_question_id: 0,
          question_group_id: quest_group[:id],
          revision_no: rev_no,
          parent_id: 0,
          order_no: quest_group[:order_no],
          flag: ""
        }
        ec_group = EvaluationCriterium.new(ec_group)
        ec_group.save
        
        # each criteria / question
        quest_group[:questions].each do |qu|
          ec_quest = {
            evaluation_plan_id: self.id,
            name: qu[:title],
            item_type: qu[:type],
            weighted_score: nil,
            question_group_id: quest_group[:id],
            evaluation_question_id: qu[:id],
            revision_no: rev_no,
            parent_id: ec_group.id,
            order_no: qu[:order_no],
            flag: "",
          }
          ec_quest = EvaluationCriterium.new(ec_quest)
          ec_quest.save
        end
      end
      # mark delete
      if rev_no - 1 >= 1
        self.evaluation_criteria.at_revision(rev_no-1).update_all(flag: DB_DELETED_FLAG)
      end
      self.revision_no = rev_no      
    end
  end
  
  def update_asst_settings(asst_params)
    # call selector rule
    self.call_settings = asst_params
    if asst_params[:enable_auto_asst] == true
      self.asst_flag = "Y"
    else
      self.asst_flag = ""
    end
  end
  
  def update_actions(rule_params)
    self.rules = rule_params
  end
  
  def current_revision_no
    if defined? @current_revision_no
      return @current_revision_no
    end
    return self.revision_no
  end
  
  def criteria(pams)
    # get criteria list of form
    # params: voice_log_id
    @criteria = []
    
    # check revision
    f_revno = self.revision_no
    q_revno = nil
    if pams[:voice_log_id].present?
      revs = EvaluationLog.revision_info(pams[:voice_log_id], self.id)
      unless revs.nil?
        f_revno = revs[:form_revision]
        @current_revision_no = f_revno
      end
    end
  
    # prepare criteria
    qcates = self.evaluation_criteria.only_category.at_revision(f_revno).order_by_default.all
    qcates.each do |qcate|
      qc = EvaluationQuestionGroup.where(id: qcate.question_group_id).first
      rs = {
        id: qc.id,
        title: qc.title,
        questions: []
      }
      
      quests = self.evaluation_criteria.only_criteria.at_revision(f_revno).detail_of(qcate.id).order_by_default.all
      quests.each do |qu|
        qs = EvaluationQuestion.where(id: qu.evaluation_question_id).first
        if q_revno.nil?
          ans = qs.evaluation_answers.last_version.first
        else
          ans = qs.evaluation_answers.at_revision(q_revno[qs.id.to_s]).first
        end
        rs[:questions] << {
          id: qs.id,
          title: qs.title,
          revision_no: ans.revision_no,
          choice_type: ans.answer_type,
          choices: ans.get_choices
        }
      end
      @criteria << rs 
    end
    
    return @criteria
  end
  
  def grades
    ds = []
    rs = self.evaluation_grades.all
    rs.each do |r|
      ds << {
        name: r.name,
        lw_score: r.lower_bound,
        up_score: r.upper_bound
      }
    end
    return ds
  end
  
  def get_rules
    self.rules = [] if self.rules.nil?
    self.rules.each do |r|
      if r["action"] == "raise_document"
        t = DocumentTemplate.where(id: r["target_id"]).first
        r["title"] = "Raise #{t.title}"
      end
    end
    return self.rules
  end
  
  def analytic_rules
    rules = []
    questions = self.evaluation_criteria.only_criteria.not_deleted.all
    questions.each do |q|
      qu = q.evaluation_question
      ans = qu.evaluation_answers.not_deleted.first
      unless ans.nil?
        ans.answer_list.each do |an|
          rule = {
            question_id: qu.id,
            question_name: qu.title,
            mapped_output: an["title"],
            rules: convert_rules(an["rules"])
          }
          rules << rule
        end
      end
    end
    return rules
  end
  
  def show_group_question?
    return (self.show_group_flag != "N")
  end

  def use_only_comment_summary?
    return (self.comment_flag != "N")
  end
  
  private

  def get_form_status
    if suspended?
      return "Disabled"
    else
      if self.evaluation_criteria.not_deleted.count(0) <= 0
        return "New"
      end
    end
    return "Enabled"
  end
  
  def get_task_attrs
    @task_conditions = {}
    sql = []
    sql << "SELECT p.evaluation_task_id, p.attr_id AS evaluation_plan_id,a.attr_type,a.attr_id,a.attr_val"
    sql << "FROM evaluation_task_attrs p"
    sql << "LEFT JOIN evaluation_task_attrs a ON p.evaluation_task_id = a.evaluation_task_id"
    sql << "AND p.attr_type <> a.attr_type"
    sql << "WHERE p.attr_type = 'form'"
    sql << "AND p.attr_id = #{self.id}"
    result = ActiveRecord::Base.connection.select_all(sql.join(" "))
    result.each do |r|
      p_id = r["evaluation_plan_id"]
      if @task_conditions[p_id].nil?
        @task_conditions[p_id] = {}
      end
      tc = @task_conditions[p_id]
      
      # call direction
      case r["attr_type"]
      when "call_direction"
        tc[:call_direction] = r["attr_val"]
      when "min_duration"
        tc[:min_duration] = r["attr_val"].to_i
      when "call_category"
        tc[:call_category] = [] if tc[:call_category].nil?
        tc[:call_category] << r["attr_val"].to_i
      end
    end
  end
  
  def criteria_changed?(quests)
    # each record will be inserted in order
    # compare structure array
    # [[<group>,<question>,<order-no>]],...]
    new_ques = []
    old_ques = []

    quests.each do |quest_group|
      quest_group[:questions].each do |qu|
        new_ques << [
          quest_group[:id].to_i,
          qu[:id].to_i
        ]
      end
    end

    self.evaluation_criteria.not_deleted.only_criteria.order(:id).all.each do |crit|
      old_ques << [
        crit.question_group_id,
        crit.evaluation_question_id
      ]
    end
    
    #STDOUT.puts new_ques.inspect
    #STDOUT.puts old_ques.inspect
    
    return (new_ques != old_ques)
  end

  def matched_condition_score(voice_log)
    
    # match call detail and form conditions and choose best form
    # check step:
    # - call category
    # - duration
    # - direction (in/out)
    
    is_matched = []
    matched_score = 0
    rules = self.call_settings
    
    if not voice_log.nil? and not rules.blank?
      
      # call category
      r_call_cate = rules["call_category"]
      
      if not r_call_cate.nil? and not r_call_cate.empty?
        cates_ok = []
        r_call_cate.each do |cates|
          cates = cates.map { |c| c.to_i } 
          voice_log.call_category_ids.each do |cate_id|
            if cates.include?(cate_id)
              cates_ok << true
              break
            end
          end
        end
        # matched if found = matched or empty
        matched_score += cates_ok.length
        is_matched << (cates_ok.length >= rules["call_category"].length)        
      end
        
      # duration
      if rules["min_duration"].present?
        if voice_log.duration.to_i > rules["min_duration"].to_i
          is_matched << true
          matched_score += 1
        else
          is_matched << false
        end
      end      
      
      # direction
      if rules["call_direction"].present?
        if voice_log.call_direction == rules["call_direction"]
          is_matched << true
          matched_score += 1
        else
          is_matched << false
        end
      end
      
      # end find score
    end

    # matched if empty? or true
    is_matched = (is_matched.empty? or (not is_matched.include?(false)))
    matched_score = -1 unless is_matched
    
    return is_matched, matched_score
  end
  
  def set_default
    begin
      self.order_no = sprintf("%03d", self.order_no.to_i)
    rescue
    end
  end
  
  def self.resolve_column_name(str)    
    unless str.empty?
      if str.match(/(grade)/)
        str = str.gsub("grade","evaluation_grade_settings.title")
      end
      if str.match(/(status)/)
        str = str.gsub("status","flag")
      end
      if str.match(/(asst_status)/)
        str = str.gsub("asst_status","asst_flag")
      end
    end
    return str
  end
  
  # end class
end
