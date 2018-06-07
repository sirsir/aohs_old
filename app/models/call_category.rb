class CallCategory < ActiveRecord::Base
  
  has_paper_trail
  
  strip_attributes  allow_empty: true,
                    collapse_spaces: true

  validates   :title, presence: true,
                      uniqueness: true,
                      length: {
                        minimum: 2,
                        maximum: 25
                      }

  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)
  }
  
  scope :private_call, ->{
    where(code_name: 'private')  
  }
  
  scope :find_id, ->(id){
    cond = {
      id: id
    }
    where(cond).first  
  }
  
  scope :find_type, ->(type){
    if type.nil? or type.blank? or type == "Call Type"
      undefined_type
    else
      where(category_type: type)
    end
  }
  
  scope :only_private, ->{
    where(code_name: ['private'])  
  }
  
  scope :order_by_default, ->{
    order(:title)
  }
  
  scope :defined_type, ->{
    where("category_type IS NOT NULL AND category_type <> ''")  
  }
  
  scope :undefined_type, ->{
    where("category_type IS NULL OR category_type = '' OR category_type = 'Other'")  
  }
  
  scope :order_by, ->(p){
    incs = []
    order_str = resolve_column_name(p)
    includes(incs).order(order_str)
  }
  
  def self.options_select(type=nil)
    return find_type(type).not_deleted.order_by_default.all.map { |c| [c.title, c.id] }
  end
  
  def self.category_types
    #cate_types = select(:category_type).not_deleted.group(:category_type)
    #cate_types = cate_types.all.map { |c| c.category_type.blank? ? "Other" : c.category_type }
    #return cate_types.uniq.sort
    cate_types = CallCategoryType.order(order_no: :desc).all
    cate_types = cate_types.map { |c| c.title }
    cate_types << "Call Type"
    return cate_types
  end
  
  def number_of_calls(days_ago=30)
    cond = {
      call_classifications: {
        call_category_id: self.id
      }
    }
    return VoiceLog.joins(:call_classifications).where(cond).days_ago(days_ago).count(0)
  end
  
  def is_locked?
    locked?
  end
  
  def locked?
    return (self.flag == DB_LOCKED_FLAG)
  end
  
  def do_delete  
    self.flag = DB_DELETED_FLAG
  end
  
  def category_type_info
    cate_type = CallCategoryType.where(title: self.category_type).first
    unless cate_type.nil?
      return cate_type
    end
    return CallCategoryType.new
  end
  
  private
  
  def self.resolve_column_name(str)  
    unless str.empty?      
    end
    return str
  end
  
end
