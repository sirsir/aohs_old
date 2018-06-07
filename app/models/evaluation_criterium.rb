class EvaluationCriterium < ActiveRecord::Base
  
  ITEM_TYPE_CATEGORY = 'category'
  ITEM_TYPE_CRITERIA = 'criteria'

  has_paper_trail
  
  belongs_to    :evaluation_plan
  belongs_to    :evaluation_question
  has_many      :evaluation_scores, foreign_key: "evaluation_criteria_id"
  has_many      :evaluation_score_logs
  has_many      :childrens, class_name: 'EvaluationCriterium', foreign_key: 'parent_id'
  belongs_to    :parent, class_name: 'EvaluationCriterium'
  
  #amoeba do
  #  enable
  #  include_association :evaluation_scores
  #end
  
  scope :only_category, ->{
    where({item_type: ITEM_TYPE_CATEGORY})
  }
  
  scope :only_criteria, ->{
    where({item_type: ITEM_TYPE_CRITERIA})
  }
  
  scope :root, ->(){
    where({parent_id: 0}).only_category.order(:order_no)  
  }
  
  scope :child_of, ->(id){
    where({parent_id: id}).only_category.order(:order_no)  
  }
  
  scope :detail_of, ->(id){
    where({parent_id: id}).only_criteria.order(:order_no)  
  }
  
  scope :not_deleted, ->{
    where.not({flag: DB_DELETED_FLAG})  
  }
  
  scope :by_plan, ->(id){
    where(evaluation_plan_id: id)  
  }
  
  scope :order_by_default, ->{
    order(:order_no)  
  }
  
  scope :at_revision, ->(no=nil){
    if no.nil? or no.to_i <= 0
      not_deleted
    else
      where(revision_no: no)
    end
  }
  
  scope :max_revision_no, ->{
    maximum(:revision_no).to_i
  }
  
  def self.find_criteria_for_report(form_id, category_id)
    
    crit = EvaluationCriterium.where(evaluation_plan_id: form_id, id: category_id).first
    eles = []
    
    if crit.nil? or crit.item_type == ITEM_TYPE_CATEGORY
      # category or root
      crits = crit.nil? ? EvaluationCriterium.where(evaluation_plan_id: form_id).root : EvaluationCriterium.child_of(crit.id)
      crits = [crit] if crits.empty?
      crits.each do |c|
        eles << {
          id: c.id,
          title: c.name,
          criteria: c.criteria_list
        }
      end
    end
    
    return eles
  
  end
  
  def self.new_category(ds={})
    
    ds[:item_type] = ITEM_TYPE_CATEGORY
    return EvaluationCriterium.new(ds)
    
  end
  
  def self.new_criteria(ds)
    
    ds[:item_type] = ITEM_TYPE_CRITERIA
    return EvaluationCriterium.new(ds)
  
  end

  def is_criteria?
    
    self.item_type == ITEM_TYPE_CRITERIA
    
  end
  
  def is_category?
    self.item_type == ITEM_TYPE_CATEGORY
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
  end

  def deleted?
    return (self.flag == DB_DELETED_FLAG)
  end
  
  def root?
    return (self.parent_id.to_i <= 0)
  end

  def child?
    return (not root?)
  end

  def na_option?
    return (self.na_flag == "Y")
  end
  
  def use_option?
    return (self.use_flag == "Y")
  end
  
  def criteria_list(item=self)
    
    crits = []
    
    if item.is_category?
      rs = EvaluationCriterium.child_of(item.id).not_deleted.all 
      if rs.empty?
        rs = EvaluationCriterium.detail_of(item.id).not_deleted.all  
      end
      rs.each do |r|
        if r.is_category?
          crits = crits.concat(criteria_list(r))
        elsif r.is_criteria?
          crits << {
            id: r.id,
            title: r.name
          }
        end
      end
    end
    
    return crits
  
  end

end
