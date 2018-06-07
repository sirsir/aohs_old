class EvaluationAnswer < ActiveRecord::Base
  
  has_paper_trail
  
  belongs_to    :evaluation_question
  
  default_value_for   :flag,  ""
  
  strip_attributes    allow_empty: true,
                      collapse_spaces: true
  
  serialize :answer_list, JSON
  serialize :ana_settings, JSON
  
  scope :by_question_id, ->(id){
    where(evaluation_question_id: id)  
  }
  
  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)  
  }
  
  scope :at_revision, ->(n=0){
    n = n.to_i
    if n > 0
      where(revision_no: n)
    else
      last_version
    end
  }
  
  scope :last_version, ->{
    order(revision_no: :desc)
  }
  
  def do_init
    update_attrs
    if self.ana_settings.nil?
      self.ana_settings = {}
    end
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
  end
  
  def display_answer_type
    self.answer_type.capitalize  
  end
  
  def has_changed?(old)
    if (old.answer_type != self.answer_type) or (old.max_score != self.max_score) or (old.answer_list != self.answer_list) or (old.ana_settings != self.ana_settings)
      return true
    end
    return false
  end
  
  def sorted_answer_list
    unless ["checkbox","numeric"].include?(self.answer_type)
      return (self.answer_list.sort { |a,b|
        a["score"] <=> b["score"]
      }).reverse
    end
    return self.answer_list
  end
  
  def get_choices
    if ["numeric"].include?(self.answer_type)
      return self.answer_list.first
    else
      return sorted_answer_list
    end
  end
  
  def analytic_rules
    unless self.answer_type == "numeric"
      ds = []
      self.answer_list.each do |ans|
        rules = mapped_rules_data(ans["rules"])
        rules = nil if rules.empty?
        if ans["score"] == 0
          # fix for score 0, is default score
          ds << {
            mapped_output: ans["title"],
            rules: "default"
          }
        else
          ds << {
            mapped_output: ans["title"],
            rules: rules
          }
        end
      end
      return ds
    end
    return nil
  end
  
  private

  def mapped_rules_data(rule)
    # not support nested rules
    ds = []
    if not rule.nil? and not rule["rules"].blank?
      rule["rules"].each do |r|
        case r["id"]
        when "template_matching"
          doc = AnalyticTemplate.where(id: r["value"]).first
          unless doc.nil?
            ds << {
              engine: 'template_matching',
              template: doc.title,
              template_id: doc.id,
              operator: r["operator"]
            }
          end
        when "talking_speed_detection"
          ds << {
            engine: 'talking_speed_detection',
            operator: r["operator"],
            value: r["value"]
          }
        when "holding_time"
          ds << {
            engine: 'slience_detection',
            operator: r["operator"],
            value: r["value"]
          }
        end
      end
    end
    return ds
  end
  
  def update_attrs
    unless self.answer_list.nil?
      reorder_answer_list
      get_max_score
      get_max_revision
    else
      self.answer_list = []
    end
  end
  
  def reorder_answer_list
    unless self.answer_type == "numeric"
      self.answer_list = (self.answer_list.sort { |a,b| a["score"] <=> b["score"] })
    end
  end
  
  def get_max_score
    max_score = 0
    self.answer_list.each do |ans|
      case self.answer_type.to_sym
      when :radio, :combo
        max_score = ans["score"] if ans["score"] >= max_score
      when :checkbox
        max_score += ans["score"].abs
      when :numeric
        max_score = ans["max_score"]
      end
    end
    self.max_score = max_score
  end
  
  def get_max_revision
    rev_no = EvaluationAnswer.by_question_id(self.evaluation_question_id).maximum(:revision_no).to_i
    self.revision_no = rev_no + 1
  end
  
end
