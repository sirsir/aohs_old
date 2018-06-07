class GroupMemberType < ActiveRecord::Base
  
  T_CHIEF = "C"
  T_SUPERVISOR = "L"
  T_LEADER = "L"
  
  has_paper_trail
  
  has_many  :group_members, foreign_key: 'member_type'
  
  scope :order_by_default, ->{
    order(order_no: :asc, id: :asc)  
  }
  
  scope :find_type, ->(x){
    where(["member_type = ? OR title = ?", x, x])
  }
  
  def self.all_types
    types = order_by_default.all.to_a
    return types
  end
  
  def self.all_types_code
    return all_types.map { |t| t.member_type }
  end
  
  def display_name
    self.title
  end
  
  def field_name
    self.title.to_s.downcase.gsub(/\s+/,"_")
  end
  
end
