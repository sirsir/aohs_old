class EvaluationQuestion < ActiveRecord::Base
  
  has_paper_trail
  
  belongs_to  :evaluation_question_group, foreign_key: :question_group_id
  has_many    :evaluation_answers
  has_many    :evaluation_criteria
  
  default_value_for :flag,  ""
  
  strip_attributes allow_empty: true,
                   collapse_spaces: true

  validates   :title,
                presence: true,
                uniqueness: {
                  conditions: -> { where(flag: "") }
                },
                length: {
                  minimum: 1,
                  maximum: 200
                }

  validates   :code_name,
                allow_blank: true,
                allow_nil: true,
                uniqueness: {
                  conditions: -> { where(flag: "") }
                }
                
  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)  
  }
  
  scope :order_by_default, ->{
    order(:order_no, :title)  
  }
  
  scope :find_by_code, ->(p){
    where(code_name: p)
  }
  
  scope :only_setcode, ->{
    where(["code_name IS NOT NULL AND code_name <> ''"])  
  }
  
  scope :order_by, ->(p){
    order_str = resolve_column_name(p)
    order(order_str)
  }
  
  def self.auto_update_order_no
    # To update order no by average order no of all forms
    result = ActiveRecord::Base.connection.select_all(sql_find_order_number)
    EvaluationQuestion.all.each do |q|
      is_found = false
      result.each_with_index do |rs, i|
        if rs["evaluation_question_id"].to_i == q.id
          q.order_no = (i + 1) * 100
          is_found = true
          break
        end
      end
      q.order_no = MAX_ORDERNO_INT unless is_found
      q.save
    end
  end

  def in_use?
    found_used_logs?
  end
  
  def can_delete?
    if not have_dependency_forms?
      return true
    end
    return false
  end
  
  def deleted?
    self.flag == DB_DELETED_FLAG
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
  end
  
  def max_score(revision_no=0)
    ans = self.evaluation_answers.last_version.first
    unless ans.nil?
      return ans.max_score
    end
    return nil
  end
  
  def dependency_forms
    crits = EvaluationCriterium.only_criteria
    crits = crits.select(:evaluation_plan_id).where(evaluation_question_id: self.id.to_i)
    return EvaluationPlan.not_deleted.where(id: crits)
  end
  
  def have_dependency_forms?
    return (dependency_forms.count(0) > 0)
  end
  
  def analytic_rules
    answer = self.evaluation_answers.not_deleted.first
    return {
      question_id: self.id,
      question: self.title,
      rules: answer.analytic_rules
    }
  end
  
  private
  
  def self.sql_find_order_number
    sql = []
    sql << "SELECT c.evaluation_question_id, c.name, c.order_no"
    sql << "FROM evaluation_criteria c"
    sql << "WHERE c.item_type = 'criteria'"
    sql << "AND flag <> 'D'"
    sql << "GROUP BY c.evaluation_question_id"
    sql << "ORDER BY order_no, AVG(c.order_no), c.name"
    return sql.join(" ")
  end
  
  def self.resolve_column_name(str)
    return str
  end
  
  def found_used_logs?
    sql = []
    sql << "SELECT 1 FROM evaluation_logs l" 
    sql << "JOIN evaluation_score_logs s ON l.id = s.evaluation_log_id"
    sql << "JOIN evaluation_plans p ON l.evaluation_plan_id = p.id"
    sql << "WHERE l.flag <> 'D' AND p.flag <> 'D'"
    sql << "AND s.evaluation_question_id = #{self.id.to_i}"
    sql << "LIMIT 1"
    sql = sql.join(" ")
    return (not ActiveRecord::Base.connection.select_all(sql).empty?)
  end
  
  # end class
end
