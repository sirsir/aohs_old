class AutoAssessmentRule < ActiveRecord::Base

  has_paper_trail
  
  strip_attributes    only: [:name, :display_name]
  serialize :rule_options, JSON
  default_value_for   :flag, value: "", allows_nil: false
  
  validates   :name,
                presence: true,
                uniqueness: true,
                length: {
                  minimum: 2,
                  maximum: 100
                }

  scope :not_deleted, -> {
    where.not({flag: DB_DELETED_FLAG})
  }
  
  scope :order_by, ->(p) {  
    incs      = []
    includes(incs).order(resolve_column_name(p))
  }
  
  scope :only_template_matching, ->{
    where(rule_type: "template_matching")  
  }
  
  scope :order_by_default, ->{
    order(name: :asc)  
  }
  
  def self.rule_type_options
    [["Template Matching","template_matching"]]  
  end
  
  def rule_options2
    begin
      return JSON.parse(self.rule_options)
    rescue
      return {}
    end
  end
  
  def rule_type_name
    self.rule_type.gsub("_"," ").to_s.capitalize  
  end
  
  def can_delete?
    return true  
  end
  
  def do_init
    self.flag = ""
    if self.display_name.blank?
      self.display_name = self.name
    end
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
  end
  
  private
  
  def self.resolve_column_name(str)
    str
  end
  
end
