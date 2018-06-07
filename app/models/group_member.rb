class GroupMember < ActiveRecord::Base
  
  # fixed member types
  T_MEMBER   = "M"       # user's location
  T_FOLLOWER = "F"       # who can view data
  
  has_paper_trail
  
  after_save   :af_update
  after_create :af_update
  
  belongs_to  :user
  belongs_to  :group
  has_many    :voice_logs, through: :user
  has_one     :group_member_type, primary_key: 'member_type', foreign_key: 'member_type'
  
  validates   :user_id,     presence: true
  validates   :group_id,    presence: true
  validates   :member_type, presence: true
  
  scope :find_by_leader_type, ->(type){
    where(member_type: type.to_s)
  }
  
  scope :not_fixed_types, ->{
    # fixed member type
    where.not(member_type: [T_MEMBER, T_FOLLOWER])
  }
  
  scope :only_member, -> {
    where(member_type: T_MEMBER)  
  }
  
  scope :only_follower, -> {
    where(member_type: T_FOLLOWER)
  }
  
  scope :only_accessable, ->{
    where(member_type: [T_FOLLOWER,T_MEMBER])
  }
  
  scope :only_leader, -> {
    where(member_type: GroupMemberType.all_types_code)  
  }
  
  scope :exclude_deleted_user, ->{
    joins("JOIN users ON users.id = group_members.user_id").where("users.state <> 'D'")  
  }
  
  scope :leader_and_member, -> {
    leader_types = GroupMemberType.all_types_code
    leader_types = leader_types.concat([T_MEMBER])
    where(member_type: leader_types)  
  }
  
  scope :our_groups, ->(p=nil) {
    leader_types = GroupMemberType.all_types_code
    leader_types = leader_types.concat([T_FOLLOWER])
    unless p.nil?
      where(member_type: leader_types, user_id: p)  
    else
      where(member_type: leader_types)
    end
  }
  
  def type_name
    case self.member_type
    when T_MEMBER
      return "Agent/Operator"
    when T_FOLLOWER
      return "Member"
    else
      unless type_info.nil?
        return type_info.display_name
      end
    end
    return "UnknownType"
  end
  
  def type_info
    unless defined? @member_type
      @member_type = self.group_member_type
    end
    return @member_type
  end
  
  def leader_info
    unless defined? @user
      @user = self.user
      @user = User.new if @user.nil?
    end
    return @user
  end
  
  def set_as_member
    set_member_type(:member)
  end
  
  def set_as_follower
    set_member_type(:follower)
  end
  
  def follower?
    return (self.member_type == T_FOLLOWER)  
  end
  
  def member?
    return (self.member_type == T_MEMBER)
  end
  
  def leader?
    return (not (member? or follower?))  
  end
  
  def is_member?
    member?
  end
  
  def do_before_delete
    af_delete
  end
  
  private
  
  def set_member_type(type)
    case type
    when :member
      self.member_type = T_MEMBER
    when :follower
      self.member_type = T_FOLLOWER
    end
  end
  
  def af_update
    update_history
  end
  
  def af_delete
    update_history(:delete)
  end
  
  def update_history(on_event=nil)
    # keep changes of group member
    return true if follower?
    cond = {
      member_type: self.member_type
    }
    if member?
      cond[:user_id] = self.user_id
    else
      cond[:group_id] = self.group_id
    end
    gmh = GroupMemberHistory.where(cond).order(created_date: :desc).first
    if gmh.nil?
      create_history
    else
      if on_event == :delete
        gmh.deleted_date = Time.now
        gmh.save
      else
        # change?
        if gmh.group_id != self.group_id or gmh.user_id != self.user_id
          gmh.deleted_date = self.updated_at
          gmh.save
          create_history
        end
      end
    end
  end
  
  def create_history
    cdate = self.created_at
    unless self.updated_at.nil?
      cdate = self.updated_at
    end
    gmh = {
      user_id: self.user_id,
      group_id: self.group_id,
      member_type: self.member_type,
      created_date: cdate,
      deleted_date: Time.now
    }
    gmx = GroupMemberHistory.new(gmh)
    gmx.save!
  end
  
end
