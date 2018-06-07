class EvaluationTaskAttr < ActiveRecord::Base
  
  # attributes task descrtiption
  ATTR_FORM           = 'form'
  ATTR_CALL_DIR       = 'call_direction'
  ATTR_CALL_LENGTH    = 'min_duration'
  ATTR_CALL_CATEGORY  = 'call_category'
  
  has_paper_trail
  
  belongs_to    :evaluation_task
  belongs_to    :evaluation_plan, ->{ where(evaluation_task_attrs: { attr_type: ATTR_FORM })}, foreign_key: :attr_id
  belongs_to    :call_category, ->{ where(evaluation_task_attrs: { attr_type: ATTR_CALL_CATEGORY })}, foreign_key: :attr_id
  
  scope :find_by_attr_id, ->(t,f){  
    cond = {
      evaluation_task_id: t,
      attr_id: f
    }
    where(cond)
  }
  
  scope :by_attr_type, ->(type){
    where({ attr_type: type })
  }
  
  scope :only_evaluation_form, ->{
    by_attr_type(ATTR_FORM)
  }
  
  scope :only_call_category, ->{
    by_attr_type(ATTR_CALL_CATEGORY)
  }
  
  scope :only_call_duration, ->{
    by_attr_type(ATTR_CALL_LENGTH)
  }

  scope :only_call_direction, ->{
    by_attr_type(ATTR_CALL_DIR)
  }
  
  scope :call_filters, ->(name=nil, value=nil, exact=false){
    # to filter with call parameters
    # duration, direction
    
    cond = nil
    if name.nil? or value.nil?
      cond = {
        attr_type: [ATTR_CALL_DIR, ATTR_CALL_LENGTH]
      }
    else
      case name
      when :call_direction
        cond = {
          attr_type:  ATTR_CALL_DIR,
          attr_val:   [value, ""]
        }
      when :call_duration
        cond = [
          "attr_type = ? AND (? >= attr_val OR attr_val = '')",
          ATTR_CALL_LENGTH, value
        ]
      end
    end
    
    where(cond)
  }
  
  def self.new_evaluation_form
    create_new_attr(ATTR_FORM)
  end
  
  def self.new_call_direction
    create_new_attr(ATTR_CALL_DIR)
  end
  
  def self.new_min_duration
    create_new_attr(ATTR_CALL_LENGTH)
  end
  
  def self.new_call_category
    create_new_attr(ATTR_CALL_CATEGORY)
  end
  
  private
  
  def self.create_new_attr(type_name)
    return new({ attr_type: type_name })
  end
  
end
