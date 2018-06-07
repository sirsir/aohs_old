class User < ActiveRecord::Base
  
  has_paper_trail     :ignore => [:encrypted_password, :text_password]
  
  default_value_for   :flag,  ""
  
  strip_attributes    allow_empty: true,
                      collapse_spaces: true
  
  attr_accessor       :old_password
  
  after_save  :af_update
  
  belongs_to  :role
  belongs_to  :user_status, -> { where(cate: SYS_USTATE) }, primary_key: "code", foreign_key: "state", class_name: "SystemConst"
  belongs_to  :user_sex, -> { where(cate: SYS_SEX) }, primary_key: "code", foreign_key: "sex", class_name: "SystemConst"
  has_one     :group_member, -> { only_member }
  has_one     :group, through: :group_member
  has_one     :avatar, class_name: 'UserPicture'
  has_many    :group_members
  has_many    :groups, through: :group_mrmbers
  has_many    :voice_logs
  has_many    :user_attributes
  has_many    :group_member_histories
  has_many    :call_tracking_logs
  has_many    :user_atl_attrs

  validates   :login,
                uniqueness: true,
                presence: true,
                format: {
                  with: /\A[a-zA-Z0-9\-\.\_]+\Z/,
                  message: 'must be contain letters, digits and special characters'
                },
                length: {
                  minimum: 3,
                  maximum: 50
                }
                
  validate    :password_complexity
  validate    :password_old_check
  
  validates   :employee_id,
                presence: true,
                uniqueness: true,
                numericality: true,
                length: {
                  minimum: 3,
                  maximum: 20
                }

  validates   :citizen_id,
                presence: true,
                uniqueness: true,
                numericality: true,
                allow_blank: true,
                allow_nil: true,                
                length: {
                  is: 13
                }

  validates   :dsr_profile_id,
                presence: true,
                allow_blank: true,
                allow_nil: true,
                format: {
                  with: /\A[A-Za-z0-9]+\z/,
                  message: "only letters and numerics"
                },
                length: {
                  minimum: 3,
                  maximum: 15
                }
                
  validates   :email,
                presence: false,
                format: {
                  with: /\A[^@\s]+@([^@.\s]+\.)+[^@.\s]+\z/
                },
                allow_blank: true,
                allow_nil: true
                
  validates   :full_name_en,
                uniqueness: {
                  case_sensitive: false,
                  conditions: -> {
                    where("users.full_name_en <> ''")
                  }
                },
                allow_blank: false,
                allow_nil: false,
                length: {
                  minimum: 3,
                  maximum: 150
                }

  validates   :full_name_th,
                uniqueness: {
                  case_sensitive: false,
                  conditions: -> {
                    where("users.full_name_th <> ''")
                  }
                },
                allow_blank: true,
                allow_nil: true,
                format: {
                  with: /[\u0E01-\u0E5B]+/,
                  message: 'must be thai charactors'
                },
                length: {
                  minimum: 3,
                  maximum: 150
                }
  
  validates   :joined_date,
                allow_blank: true,
                allow_nil: true,
                format: {
                  with: /(\d{4}-\d{2}-\d{2})/
                },
                if: :valid_joined_date?

  validates   :dob,
                allow_blank: true,
                allow_nil: true,
                format: {
                  with: /(\d{4}-\d{2}-\d{2})/
                },
                if: :valid_dob?
                
  devise      :database_authenticatable,
              :trackable,
              :validatable,
              :rememberable,
              :session_limitable,
              :lockable,
              :timeoutable
              #:password_expirable
              #:recoverable,
              #:confirmable,
  
  scope :find_id, ->(uid){
    where({ id: uid }).first
  }
  
  scope :find_email, ->(p){
    where({ id: p })  
  }
  
  scope :select_only, ->(type){
    case type
    when :names
      select([:id,:login,:full_name_th,:full_name_en])
    end
  }
  
  scope :only_active, ->{
    where({ state: STATE_ACTIVE })
  }
  
  scope :only_inactive, ->{
    where({ state: STATE_SUSPEND })  
  }
  
  scope :only_deleted, ->{
    where({ state: STATE_DELETE })
  }
  
  scope :not_deleted, ->{
    where.not({ state: STATE_DELETE })
  }
  
  scope :not_locked, ->{
    where.not({ flag: DB_LOCKED_FLAG })
  }
  
  scope :evaluator, ->{
    roles = Role.evaluator.all
    where({ role_id:  roles.map { |r| r.id }})
  }
  
  scope :full_name_cont, ->(p){
    where('full_name_th LIKE :full_name OR full_name_en LIKE :full_name',full_name: "%#{p}%")
  }
  
  scope :name_like, ->(p){
    where('login LIKE :name OR full_name_th LIKE :name OR full_name_en LIKE :name',name: "%#{p}%")
  }
  
  scope :group_member_in, ->(p){
    joins(:group_member).where({group_members: {group_id: p}})
  }
  
  scope :flag_undefined, ->{
    where({ flag: "" })
  }
  
  scope :have_email, ->{
    where("email IS NOT NULL and email <> ''")  
  }
  
  scope :no_password, ->{
    where(["encrypted_password IS NULL OR encrypted_password = ''"])  
  }
  
  scope :in_region, ->(p) {
    where("region_code=?", p)
  }

  scope :in_section_id, ->(p) {
    where("section_id=?", p)
  }

  scope :in_branch_code, ->(p) {
    where("branch_code=?", p)
  }

  scope :order_by, ->(p) {
    incs = []
    order_str = resolve_column_name(p)

    incs << :group if order_str.match(/(groups)/)
    incs << :role if order_str.match(/(roles)/)

    includes(incs).order(order_str)
  }

  
  default_scope {
    joins("LEFT JOIN user_atl_attrs a1 ON users.id = a1.user_id AND a1.flag <> 'D' LEFT JOIN (SELECT user_id, MAX(id) AS a_id FROM user_atl_attrs a3 WHERE a3.flag <> 'D' GROUP BY user_id) a2 ON a1.id = a2.a_id")
    .joins("LEFT JOIN (SELECT u.id, a1.attr_val AS branch_code, a2.attr_val AS region_code FROM users u JOIN user_attributes a1 ON u.id = a1.user_id AND a1.attr_type = 102 JOIN user_attributes a2 ON u.id = a2.user_id AND a2.attr_type = 103 ) br ON br.id=users.id")
  }

  scope :only_evaluators, ->{
    user_ids = EvaluationLog.select("DISTINCT evaluated_by").not_deleted.ndays_ago(15).all
    return User.where(id: user_ids.map { |u| u.evaluated_by })
  }
  
  scope :performance_group_eq, ->(p){
    sqlo = UserAtlAttr.where(performance_group_id: p)
    sqlo = sqlo.select("1").where("users.id = user_atl_attrs.user_id").not_deleted
    where("EXISTS (#{sqlo.to_sql})")
  }
  
  scope :section_eq, ->(p){
    sqlo = UserAtlAttr.where(section_id: p)
    sqlo = sqlo.select("1").where("users.id = user_atl_attrs.user_id").not_deleted
    where("EXISTS (#{sqlo.to_sql})")
  }
  
  def self.extract_search_name(txt)
    return txt  
  end

  def self.ransack_ext(usr,p)
    Rails.logger.debug '----------ransack'
    Rails.logger.debug p
    unless p['region'].nil? or p['region'].empty?
      usr = usr.in_region(p['region'])
    end
    unless p['branch_code'].nil? or p['branch_code'].empty?
      usr = usr.in_branch_code(p['branch_code'])
    end    
    usr
  end
  
  def self.display_name(usr)
    lang = Settings.user.display_name.to_sym
    dsp_name = nil
    if lang == :th and not usr.full_name_th.empty?
      dsp_name = usr.full_name_th
    else
      dsp_name = usr.full_name_en
    end
    return dsp_name
  end

  def self.get_group_info(user_id)
    group_member = GroupMember.only_member.where(user_id: user_id).first
    unless group_member.nil?
      group = group_member.group
      unless group.nil?
        return group
      end
    end
    return nil
  end
  
  def self.find_or_create_ldap_account(login, domain_name, password, attrs={})
    user = User.only_active.where(login: login).first
    role = Role.find_role_by_ldap_dn(attrs)
    group = Group.find_group_by_ldap_dn(attrs)
    if user.nil?
      emp_id = Time.now.strftime("%Y%m%d%H%M")
      user = {
        login: login,
        employee_id: emp_id,
        full_name_en: attrs[:displayname].first || login,
        role_id: role.id,
        password: password,
        #password_confirmation: password,
        domain_name: domain_name,
        auth_type: 'ldap',
        flag: ''
      }
      user = User.new(user)
      if not (user.do_active(true) and user.save)
        group_member = user.new_group_member
        group_member.set_as_member
        group_member.group_id = group.id
        group_member.save
        Rails.logger.error "Error create new account for LDAP:" + user.errors.full_messages.inspect
        user = nil
      end
    else
      begin
        user.domain_name = domain_name
        user.auth_type = 'ldap'
        user.role_id = role.id
        user.save
        group_member = user.group_member
        group_member = user.new_group_member if group_member.nil?
        group_member.group_id = group.id
        group_member.save
      rescue => e
        Rails.logger.error "Error update account for LDAP:" + e.message
      end
    end
    unless user.nil?
      UserAttribute.update_ldap_info(user.id, attrs)
    end
    return user
  end
  
  def display_name
    return User.display_name(self) 
  end
  
  def full_name
    return display_name
  end

  def work_days(at_date=Date.today)
    unless self.joined_date.nil?
      return (at_date - Date.parse(self.joined_date.to_formatted_s)).to_i
    end
    return nil
  end
  
  def mail_name  
    return "#{self.email} (#{full_name})"
  end
  
  def role_name
    get_role    
    return @role.name
  end
  
  def state_name
    return self.user_status.name
  end
  
  def ldap_auth?
    self.auth_type == "ldap"
  end
  
  def authen_type_name
    case self.auth_type
    when "ldap"
      return "LDAP"
    end
    return "Web"
  end
  
  def sex_name
    return self.user_sex.name  
  end
    
  def group_info(options={})
    unless defined? @group
      @group = nil
      begin
        @group = self.group_member.group
      rescue
      end
      if options[:evaluation_log] == true
        log = last_evalution_group_info
        unless log.nil?
          @group = Group.where(id: log.group_id).first
        end
      end
      @group = Group.new if @group.nil?
    end
    return @group
  end
  
  def group_name(show_short_name=true)
    if show_short_name
      return group_info.short_name
    end
    return group_info.pathname
  end

  def group_id
    return group_info.id
  end

  def super_admin?
    begin
      sunames = Settings.user.suadmin.split(",")
      return sunames.include?(self.login.downcase)
    rescue
    end
    return false
  end
  
  def is_admin?
    get_role
    unless @role.nil?
      return @role.is_admin?
    end
    return false
  end
  
  def is_agent?
    get_role
    return @role.is_agent?
  end
  
  def is_locked?
    return (self.flag == DB_LOCKED_FLAG)
  end
  
  def suspend?
    return (self.state != STATE_ACTIVE)
  end
  
  def was_deleted?
    return (self.state == STATE_DELETE)
  end
  
  def new_group_member
    gm = GroupMember.new
    gm.set_as_member
    gm.user_id = self.id
    return gm
  end
  
  def reset_default_password
    if is_admin?
      # administrator password
      if self.login == Settings.user.admin.username
        # su administrator password
        self.password = Settings.user.admin.password_default
        self.password_confirmation = Settings.user.admin.password_default
      else
        self.password = Settings.user.password_admin
        self.password_confirmation = Settings.user.password_admin
      end
    else
      # general users
      self.password = Settings.user.password_default
      self.password_confirmation = Settings.user.password_default
    end
  end
  
  def set_password_with_parm(auth_params)
    if auth_params[:password].present?
      self.old_password = auth_params[:old_password]
    end
    self.password = auth_params[:password]
    self.password_confirmation = auth_params[:password_confirmation]
    self.password_changed_at = Time.now.to_formatted_s(:db)
  end
  
  def do_active(reset_password=false)
    if reset_password
      reset_default_password
    end
    self.state = STATE_ACTIVE
    return true
  end

  def do_delete
    self.state      = STATE_DELETE
    self.deleted_at = Time.now
    return true
  end
  
  def do_suspend
    self.state = STATE_SUSPEND
    return true
  end
  
  def do_undelete
    return (do_active ? true : false)
  end
  
  def compare_role_priority(user_id)
    r = Role.select("roles.priority_no").joins(:users).where({ users: { id: user_id }}).first
    unless r.nil?
      diff = role_priority - r.priority_no.to_i
      if diff < 0
        # self is lower
        return :higher
      elsif diff > 0
        # self is higher
        return :lower
      else
        return :equal
      end
    end
    return :error
  end
  
  def permiss_users
    # To find list of users which is under this user
    # That find from groups
    groups = permiss_groups
    # have groups and not lock only me/own
    if (not groups.empty?) and (not is_only_own_call?)
      users = GroupMember.select([:user_id]).only_accessable.where(group_id: groups).all
      @permiss_users = users.map { |u| u.user_id }
      # takeout lower role priority
      @permiss_users.delete_if { |uid| compare_role_priority(uid) == :higher }
    elsif is_only_own_call?
      # only own data.
      @permiss_users = [self.id]
    end
    return @permiss_users
  end
  
  def permiss_groups
    # To find all possible groups which under this user
    unless defined?(@permiss_groups)
      groups = self.group_members.select("DISTINCT group_id").all
      tmp = []
      groups.each do |g|
        # parent group id
        tmp << g.group_id
        # child group id
        cgrp = g.group.all_childs
        cgrp.each {|cg| tmp << cg.id }
      end
      @permiss_groups = tmp.uniq
    end
    return @permiss_groups
  end
  
  def is_only_own_call?
    return (not SysPermission.can_do?(self.id,:voice_logs,'not_only_own_call'))
  end
  
  def qa_func?
    return true
  end

  def update_attr(attr)
    ua = UserAttribute.create_or_update(self.id, attr[:attr_type], attr[:attr_val])
  end
  
  def update_attrs(attrs)
    if not attrs.nil? and not attrs.empty?
      attrs.each do |atr|
        update_attr({ attr_type: atr[:id], attr_val: atr[:value]})
      end
    end
  end
  
  def user_attr(name_or_id)
    atr = UserAttribute.where(user_id: self.id).order(updated_at: :desc)
    if /\A\d+\z/ === name_or_id or name_or_id.is_a?(Integer)
      atr = atr.attr_type(name_or_id).first
    else
      atr = atr.attr_name(name_or_id).first
    end
    if atr.nil?
      return UserAttribute.new
    else
      return atr      
    end
  end
  
  def after_database_authentication
    # keep login history to operation log
    ds = {
      created_at: self.current_sign_in_at,
      log_type: "INFO",
      module_name: "Session",
      event_type: "login",
      created_by: self.login,
      remote_ip: self.current_sign_in_ip
    }
    op = OperationLog.new(ds)
    op.save!
  end
  
  def self.evaluator_options(opts={})
    evaluators_id = EvaluationLog.select("DISTINCT evaluated_by").ndays_ago(30).all
    all_users = User.not_deleted.where(id: evaluators_id.map { |x| x.evaluated_by }).order(:login).all
    return all_users.all.map { |o| [o.display_name,o.id] }
  end
  
  def self.user_options(opts={})
    all_users = User.not_deleted.order("login")
    if opts[:role] == :staff_and_upper
      all_users = all_users.where(role_id: Role.staff_and_upper)
    end
    return all_users.all.map { |o| [o.display_name,o.id] }
  end
  
  def active_for_authentication?
    super && !suspend?
  end

  def inactive_message
    return "This account has been disabled."
  end
  
  def lock_expire_at
    return Time.now + (locked_at - self.class.unlock_in.ago)
  end
  
  def landing_page_or_default
    ld_page = self.role.landing_page
    if ld_page.blank?
      'default'
    else
      ld_page
    end
  end
  
  def role_priority
    get_role
    return @role.priority_no
  end
  
  def get_last_evaluation_log
    unless defined? @last_evaluation_log
      last_evalution_group_info
    end
    @last_evaluation_log
  end

  def password_expired?
    expiry_days = Settings.user.password_expiry_days.to_i
    return last_password_changed_at <= expiry_days.days.ago
  end
  
  protected
  
  def get_role
    unless defined? @role
      @role = self.role
    end
  end
  
  def get_group
    return group_info
  end
  
  def af_update
    case self.state
    when STATE_DELETE
      af_delete
    when STATE_ACTIVE
      af_active
    when STATE_SUSPEND
      # [TODO]
    end
  end
  
  def af_delete
    # remove all followers
    groups = GroupMember.only_follower.where(user_id: self.id).all
    unless groups.empty?
      groups.each { |g| d.delete }
    end
    
    # remove extension
    exts = Extension.where(user_id: self.id).all
    unless exts.empty?
      exts.each {|x| x.delete }
    end
    
  end
  
  def af_active
    
    group = GroupMember.only_member.where(user_id: self.id).first
    if group.nil?
      # group missing
      # [TODO]
    end
    
  end
  
  def valid_joined_date?
    
    unless self.joined_date.nil?
      unless self.joined_date <= (Date.today + 30.days)
        errors.add(:joined_date, 'invalid date')
      end
    end
    
    return true
  
  end
  
  def valid_dob?

    unless self.dob.nil?
      unless self.dob < Date.today
        errors.add(:dob, 'invalid date')
      end
    end
    
    return true
  
  end

  def email_required?
    # remove required email field.
    false
  end
    
  def last_password_changed_at
    unless self.password_changed_at.blank?
      return self.password_changed_at
    else
      return self.updated_at
    end
  end
  
  def password_complexity
    # To valid password policy and complexity
    # - one uppercase
    # - one lowercase
    # - one digit
    # - one special character
    
    if self.password.present?
      password_regexp = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*\(\)\_\-=\{\}\[\]\<\>\?\.\|\/\\])/
      unless self.password.match(password_regexp)
        errors.add :password, "must include at least one lowercase letter, one uppercase letter, one digit and special character."
      end
      #if (not is_admin?) and password_expired? and valid_password?(self.password)
      #  # not allowed to re-use password if old password expired
      #  errors.add :password, "must have not used before."
      #end
    end
  end

  def password_old_check
    # To check old password for change password
    if self.password.present? and self.old_password.present?
      unless valid_password?(self.old_password)
        errors.add :old_password, "is incorrect"
      end
    end
  end
  
  def last_evalution_group_info
    log = EvaluationLog.not_deleted.where(user_id: self.id).ndays_ago(30).order(updated_at: :desc)
    log = log.select(:user_id, :group_id, :supervisor_id, :chief_id).first
    @last_evaluation_log = log
    return @last_evaluation_log
  end
  
  def self.ransackable_scopes(auth_object = nil)
    
    %i(full_name_cont group_member_in performance_group_eq section_eq)
  
  end
  
  def self.resolve_column_name(str)
    
    unless str.empty?
      
      if str.match(/(group_name)/)
        str = str.gsub("group_name","groups.name")
      end
      
      if str.match(/(role_name)/)
        str = str.gsub("role_name","roles.name")
      end
      
      if str.match(/(full_name)/)
        str = str.gsub("full_name","full_name_en")
      end
      
    end
    
    return str
    
  end
  
end
