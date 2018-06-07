
#
# data definition
# a. role level
#   A = Administrator
#   M = Management
#   S = Officer/Staff
#   O = Operator
#

class Role < ActiveRecord::Base
  
  has_paper_trail
  
  has_many    :users
  has_many    :permissions
  
  before_create   :bf_update
  before_save     :bf_update
  
  strip_attributes  only: [:name, :desc, :ldap_dn],
                    allow_empty: true,
                    collapse_spaces: true

  validates   :name,
                presence: true,
                uniqueness: {
                  case_sensitive: false,
                  conditions: -> {
                    where(["flag <> ?", DB_DELETED_FLAG])
                  }                        
                },
                length: {
                  minimum: 2,
                  maximum: 20
                }

  validates   :ldap_dn,
                allow_blank: true,
                allow_nil: true,
                length: {
                  minimum: 3,
                  maximum: 150
                }
                
  validates   :level,
                presence: {
                  message: "choose one"
                }

  scope :not_deleted, -> {
    where.not({ flag: DB_DELETED_FLAG })
  }
  
  scope :only_admin, -> {
    where({ level: 'A' })
  }
  
  scope :only_management, -> {
    where({ level: 'M' })  
  }
  
  scope :only_operator, -> {
    where({ level: 'O' })  
  }
  
  scope :not_admin, -> {
    where.not({ level: 'A' })  
  }
  
  scope :default, ->{
    not_deleted.order(id: :desc).first
  }

  scope :evaluator, -> {
    roles = Permission.select(:role_id).where({ privilege_id: Privilege.select(:id).where({ module_name: "evaluations", event_name: ["view", "evaluate", "modify"] }) })
    roles = roles.map { |r| r.role_id }
    where({ id: roles, level: ['A','M','S'] })
  }
  
  scope :staff_and_upper, -> {
    where({ level: ['A','M','S'] })
  }
  
  scope :order_by, ->(p) {
    incs      = []
    order_str = resolve_column_name(p)
    includes(incs).order(order_str)
  }
  
  def self.get_priority_no(role_id)
    ro = Role.select(:id, :priority_no).where(id: role_id).first
    unless ro.nil?
      return ro.priority_no.to_i
    end
    return 0
  end
  
  def self.role_heigher(role_id1, role_id2, same_p=false)
    rop1 = get_priority_no(role_id1)
    rop2 = get_priority_no(role_id2)
    Rails.logger.info "Checked role priority #{role_id1}:#{rop1} >> #{role_id2}:#{rop2}"
    if same_p
      return (rop1 >= rop2)
    end
    return (rop1 > rop2)
  end
  
  def self.role_equal_or_heigher(role_id1, role_id2)
    return role_heigher(role_id1, role_id2, true)
  end
  
  def self.operation_role_codes
    return ['O', 'S']  
  end
  
  def total_users
    if not defined? @total_users
      @total_users = self.users.not_deleted.count
    end
    @total_users
  end
  
  def role_type_name
    case self.level.to_s
    when "A"
      return "Admintrator"
    when "M"
      return "Manager"
    when "S"
      return "Officer/Staff"
    when "O"
      return "Agent/Operator"
    else
      return ""
    end
  end
  
  def can_delete?
    return (not is_locked? and not got_users?)
  end
  
  def admin_role?
    return (self.level == 'A')
  end
  
  def is_admin?
    return admin_role?
  end
  
  def not_admin?
    return (not is_admin?)
  end
  
  def is_agent?
    return (self.level == 'O')
  end
  
  def is_locked?
    return (self.flag == DB_LOCKED_FLAG)
  end
  
  def got_users?
    return (total_users > 0)  
  end
  
  def dn_list
    return self.ldap_dn.to_s.split("|").map{ |d| d.split(",") }  
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
    self.priority_no  = 0
  end
  
  def self.role_options
    order("name").not_deleted.all.map { |o| [o.name,o.id] }
  end

  def self.priority_options
    priority_values.map { |o| [o,o] }
  end

  def self.type_options
    return [
      ['Administrator', 'A'],
      ['Manager', 'M'],
      ['Officer/Staff', 'S'],
      ['Agent/Operator', 'O']
    ]
  end

  def self.max_priority
    maximum(:priority_no)
  end
  
  def self.priority_values
    
    l = []
    m = 1
    n = not_deleted.all.count + 1
    
    if n > 1
      m = maximum(:priority_no).to_i / 10
      n = m if m > n
    end
    
    n.times do |nx|
      l << (nx + 1) * 10
    end
    
    return l

  end
  
  def self.update_admin_priority
    
    # update role priority of admin to maximum
    
    admin_roles = where(name: ROLE_ADMIN_GROUP).all
    max_pri     = max_priority
    
    admin_roles.each do |ar|
      unless ar.priority_no == max_pri
        ar.priority_no = max_pri
        ar.save
      end
    end

  end
  
  def self.find_role_by_ldap_dn(attrs)
    list = attrs[Settings.ldap_auth.role_attribute]
    unless list.empty?
      list = list.map { |d| d.split(",").sort }
      Role.not_deleted.each do |role|
        role.dn_list.each do |la|
          list.each do |lb|
            if (la - lb).empty?
              Rails.logger.info "Found role #{role.name}, '#{la.inspect}' <-> '#{lb.inspect}'"
              return role
            end
          end
        end
      end
    end
    Rails.logger.info "Not found any role, will use default. '#{list.inspect}'"
    return Role.default
  end

  def do_init
    self.priority_no = 20
    self.flag = "S"
    self.level = "S"
    self.landing_page = "default"
  end
  
  private
  
  def bf_update
    self.name.to_s.capitalize
  end

  def self.resolve_column_name(str)
    unless str.empty?
      if str.match(/(priority)/)
        str = str.gsub("priority","roles.priority_no")
      end
    end
    return str
  end
  
end
