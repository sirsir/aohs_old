class GroupMemberHistory < ActiveRecord::Base
  
  belongs_to   :group
  belongs_to   :user
  
  scope :only_member, -> {
    where(member_type: GroupMember::T_MEMBER)  
  }
  
  scope :only_leader, -> {
    where(member_type: GroupMemberType.all_types_code)  
  }
  
  def type_name
    if member_type?
      return "Member"
    else
      return type_info.display_name rescue "UnknownType"
    end
  end
  
  def type_info
    unless defined? @member_type
      @member_type = GroupMemberType.where(member_type: self.member_type).first
    end
    return @member_type
  end
  
  def member_type?
    return (self.member_type == "M")
  end
  
  def leader_type?
    return (not member_type?)
  end
  
end
