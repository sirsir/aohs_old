class Group < ActiveRecord::Base
  
  MAXIMUM_LEVELS      = 2
  DEFAULT_PARENT_ID   = 0
  
  has_paper_trail
  
  has_many      :group_members
  has_many      :childrens, class_name: "Group", foreign_key: "parent_id"
  belongs_to    :parent, class_name: "Group"
  has_one       :group_leader, -> { only_leader }, class_name: "GroupMember"
  has_many      :group_member_histories
  has_many      :leaders, ->{ only_leader }, class_name: "GroupMember"
  
  before_save   :bf_update
  before_create :bf_update  
  after_save    :af_update
  before_validation :bf_valid
  
  strip_attributes  allow_empty: true,
                    collapse_spaces: true
  
  validates :short_name,
              presence: true,
              uniqueness: {
                case_sensitive: false,
                scope: :parent_id,
                conditions: -> {
                  where(flag: "")
                }
              },
              length: {
                minimum: 2,
                maximum: 50
              }

  validates :level_no,
              numericality: {
                only_integer: true
              },
              inclusion: {
                in: 0..MAXIMUM_LEVELS
              }
  
  validates :description,
                allow_blank: true,
                allow_nil: true,
                length: {
                  minimum: 3,
                  maximum: 100
                }

  validates   :ldap_dn,
                allow_blank: true,
                allow_nil: true,
                length: {
                  minimum: 3,
                  maximum: 150
                }
                
  scope :not_deleted, ->{
    where(["flag <> ?",DB_DELETED_FLAG])
  }
  
  scope :with_level, ->(p){
    where(level_no: p).not_deleted
  }
  
  scope :root, ->{
    where(parent_id: 0).not_deleted
  }
  
  scope :name_like, ->(p){
    where(["groups.short_name LIKE ?",p])  
  }
  
  scope :default_group, ->{
    where(short_name: "OTHER").first
  }
  
  scope :by_leader_id, ->(leader_id){
    group_ids = GroupMember.select(:group_id).only_leader.where(user_id: leader_id).all
    where(id: group_ids.map { |g| g.group_id })
  }
  
  def self.all_group_options(opts={})
    if opts[:exclude].present?
      group = Group.where(id: opts[:exclude]).first
      exc_groups = 0
      unless group.nil?
        exc_groups = group.all_childs.to_a.map { |g| g.id }
        exc_groups << opts[:exclude]
      end
      all_groups = Group.not_deleted.where.not(id: exc_groups).order("seq_no")
    else
      all_groups = Group.order("seq_no").not_deleted
    end
    if opts[:user_id].present?
      no_chk_required = SysPermission.can_do?(opts[:user_id],"voice_logs","disabled_call_permission")      
      unless no_chk_required
        our_groups = User.where(id: opts[:user_id]).first.permiss_groups
        all_groups = all_groups.where(id: our_groups)   
      end
    end
    return all_groups.all.map { |o| ["#{ "-" * (o.level_no.to_i * Settings.style.group.nof_indent.to_i) } #{o.short_name}",o.id] }
  end

  def self.find_group_by_ldap_dn(attrs)
    list = attrs[Settings.ldap_auth.group_attribute]
    unless list.empty?
      list = [list] unless list.is_a?(Array)
      list = list.map { |d| d.split(",").sort }
      Group.not_deleted.each do |group|
        group.dn_list.each do |la|
          list.each do |lb|
            if (la - lb).empty?
              Rails.logger.info "Found group #{group.name}, '#{la.inspect}' <-> '#{lb.inspect}'"
              return group
            end
          end
        end
      end
    end
    return Group.default_group
  end
  
  def parent_group_options
    group_id = self.id.to_i
    return Group.all_group_options({ exclude: group_id })
  end
  
  def init_leaders(leaders_params=[])
    # To initialize leaders list for create or edit
    list = []
    GroupMemberType.all_types.each do |leader_type|
      leader = (leaders_params.select { |l| l[:member_type] == leader_type.member_type }).first
      unless leader.nil?
        # from params
        list << GroupMember.new(leader)
      else
        leader = self.group_members.find_by_leader_type(leader_type.member_type).first
        unless leader.nil?
          # from db
          list << leader
        else
          # new
          list << GroupMember.new({ member_type: leader_type.member_type })
        end
      end
    end
    return list
  end
  
  def leader_info(type=nil, options={})
    # options
    # type
    # evaluation_log
    
    @leaders = init_leaders

    # update from evaluation log
    unless options[:evaluation_log].nil?
      log = options[:evaluation_log]
      @leaders.each do |l|
        # leader/supervisor
        if l.member_type == GroupMemberType::T_LEADER and defined? log.supervisor_id
          l.user_id = log.supervisor_id
        end
        # cheif
        if l.member_type == GroupMemberType::T_CHIEF and defined? log.chief_id
          l.user_id = log.chief_id
        end
      end
    end
    
    unless type.nil?
      return (@leaders.select { |l| l.member_type == type }).first
    end
    return @leaders
  end
  
  def display_name
    return self.pathname
  end
  
  def group_name
    return self.name
  end
  
  def leader_name
    unless defined? @leader
      @leader = self.group_leader.user rescue nil
    end
    return @leader.display_name rescue nil
  end
  
  def leader_role
    return @leader.role_name rescue nil
  end
  
  def is_locked?
    return (self.flag == DB_LOCKED_FLAG)
  end  
  
  def is_deleted?
    return (self.flag == DB_DELETED_FLAG)
  end
  
  def do_locked
    self.flag = DB_LOCKED_FLAG  
  end
  
  def seq_no2
    return (self.seq_no.split(".").map { |x| x.to_i }).join(".")
  end
  
  def count_members
    return self.group_members.only_member.exclude_deleted_user.count(0)
  end
  
  def list_members_id
    return self.group_members.only_member.exclude_deleted_user.all.map { |m| m.user_id }
  end
  
  def has_member?
    return (self.group_members.only_member.exclude_deleted_user.count > 0)
  end

  def have_members?
     return (self.group_members.exclude_deleted_user.count > 0)
  end
  
  def have_children?
    return (self.childrens.not_deleted.count > 0)
  end
  
  def can_delete?
    
    return (not is_locked? and not has_member? and not have_children?)
  
  end
  
  def do_init
    self.parent_id = DEFAULT_PARENT_ID if self.parent_id.nil?
    self.name = self.short_name
  end
  
  def do_delete
    
    if not have_children?
      self.parent_id = DEFAULT_PARENT_ID
      self.flag = DB_DELETED_FLAG      
    end
    
  end

  def all_childs
    
    return Group.where(["seq_no LIKE ?","#{self.seq_no}.%"]).all.to_a
  
  end

  def dn_list
    return self.ldap_dn.to_s.split("|").map{ |d| d.split(",") }  
  end
  
  def update_leader(leader_params)
    return false if self.id <= 0
    # update records
    updated_types = []
    leader_params.each do |leader|
      next if leader[:user_id].to_i <= 0
      o_leader = self.group_members.find_by_leader_type(leader[:member_type]).first
      if o_leader.nil?
        o_leader = self.group_members.new(leader)
      else
        o_leader.user_id = leader[:user_id]
      end
      o_leader.save
      updated_types << o_leader.member_type
    end
    # remove no update
    unused_records = self.group_members.not_fixed_types.where.not(member_type: updated_types)
    unless unused_records.empty?
      unused_records.delete_all
    end
  end
  


  def self.repair_and_update_sequence_no(node=nil)
    
    # groups.seq_no
    # level-0.level-1.level-2.level-n
    
    if node.nil?
      nodes = Group.with_level(0).order("name").all
    else
      nodes = node.childrens.not_deleted.all
    end
    
    nodes.each_with_index do |nx,i|
      
      if node.nil?
        seq_no   = seq_format((i+1).to_s)
        pathname = nx.short_name
      else
        seq_no   = [node.seq_no,seq_format((i+1).to_s)].join(GROUP_SEQ_DELIMETER)
        pathname = [node.pathname,nx.short_name].join(GROUP_PATH_DELIMETER) 
      end
      
      nx.seq_no   = seq_no
      nx.pathname = pathname
      nx.save
      
      repair_and_update_sequence_no(nx)
      
    end
    
  end
  
  def parent_group?
    return (self.parent_id.to_i > 0)  
  end
  
  def parent_groups
    pa_groups = []
    if parent_group?
      pa_group = self.parent
      unless pa_group.nil?
        pa_groups << pa_group
        pa_groups.concat(pa_group.parent_groups)
      end
    end
    return pa_groups.compact
  end

  private
      
  def bf_update
    
    if self.parent_id.nil?
      self.parent_id = DEFAULT_PARENT_ID
    end    
    
    if self.name.to_s.empty?
      self.name = self.short_name
    end
    
    # update level no for treeview
    parent_group = Group.where(id: self.parent_id.to_i).not_deleted.first
    self.level_no = 0
    unless parent_group.nil?
      self.level_no = parent_group.level_no.to_i + 1
    end
  
  end
  
  def af_update
    
    if self.flag == DB_DELETED_FLAG  
      group_members = GroupMember.only_follower.where(group_id: self.id).all
      unless group_members.empty?
        group_members.each { |gm| gm.delete }
      end
    end
    
  end
  
  def bf_valid
    
    begin
      self.parent_id = self.parent_id.to_i
    rescue
      self.parent_id = 0
    end
    
  end
  
  def self.seq_format(seq)
    
    seq = seq.strip
    
    (3 - seq.length).times do
      seq = "0".concat(seq)
    end
      
    return seq
  
  end

end
