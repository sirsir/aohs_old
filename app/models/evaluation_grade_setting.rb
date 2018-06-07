class EvaluationGradeSetting < ActiveRecord::Base

  has_paper_trail
  
  default_value_for :flag,  ""
  
  strip_attributes  allow_empty: true,
                    collapse_spaces: true

  has_many    :evaluation_grades
  has_many    :evaluation_plans
  
  validates :title, presence: true,
                    uniqueness: true,
                    length: {
                      minimum: 2,
                      maximum: 25
                    }

  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)  
  }

  scope :order_by_default, ->{
    order(:title)
  }

  def self.select_options(current_option_id=0)
    options = where(["(flag <> ?) OR (id = ?)", DB_DELETED_FLAG, current_option_id])
    options.order_by_default.all.map { |o| [o.title, o.id] }
  end
  
  def can_delete?
    if found_inuse_form?
      return false
    end
    return true
  end

  def do_delete
    self.flag = DB_DELETED_FLAG
  end
    
  def form_count
    unless defined? @form_count
      @form_count = self.evaluation_plans.not_deleted.count(0) rescue 0
    end
    return @form_count
  end
  
  def update_score_range(score_scales)
    scales = []
    # find old records
    old_scales = self.evaluation_grades.all
    # remove old records
    unless old_scales.empty?
      old_scales.each { |sc| sc.delete }
    end
    # add new records
    score_scales.each do |sc|
      new_sc = {
        evaluation_grade_setting_id: self.id,
        name: sc[:title],
        lower_bound: sc[:lower_bound],
        upper_bound: sc[:upper_bound]
      }
      new_sc = EvaluationGrade.new(new_sc)
      new_sc.save
      scales << sc
    end
    return scales
  end
  
  def update_grade_point
    max_grade_point = 10.0
    scales = self.evaluation_grades.order(upper_bound: :desc).all
    total_rec = scales.count(0)
    if total_rec > 0
      scales.each_with_index do |sc,i|
        sc.point = (max_grade_point - (max_grade_point/total_rec.to_f*i)).round(2)
        sc.save
      end
    end
  end
  
  private

  def found_inuse_form?
    return (form_count > 0)  
  end
  
  # end class
end
