require 'digest/sha1'

class User < ActiveRecord::Base

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::StatefulRoles
  include AuthenticationRule::Password
  
  belongs_to :group, :class_name => 'Group',  :foreign_key => 'group_id'
  belongs_to :role,  :class_name => 'Role',   :foreign_key => 'role_id'  
  
  validates :login, :presence   => true,
                    #:uniqueness => true,
                    :length     => { :within => 3..40 },
                    :format     => { :with => Authentication.login_regex, :message => Authentication.bad_login_message }

  validates_uniqueness_of :login, :scope => :flag
  
  validates :display_name,  :presence   => true,
                            :format     => { :with => Authentication.name_regex, :message => Authentication.bad_name_message },
                            :length     => { :maximum => 100 }
  
  validates_presence_of     :type
	
  validates :email, :format     => { :with => Authentication.email_regex, :message => Authentication.bad_email_message },
                    :length     => { :within => 6..100 },
                    #:allow_nil  => true,
                    :allow_blank => true

  validates_format_of :password, :allow_nil  => true, :allow_blank => true, :with => /(\!|\@|\#|\$|\%|\<|\>\&|\*|\=|\+|\-|\(|\)){1,}/, :message => "must be contains special characters"
  validates_format_of :password, :allow_nil  => true, :allow_blank => true, :with => /[a-zA-Z]{1,}/, :message => "must be contains a-z or A-Z" 					   
  validates_format_of :password, :allow_nil  => true, :allow_blank => true, :with => /[0-9]{1,}/, :message => "must be contains digit" 
  validates_length_of :password, :allow_nil  => true, :allow_blank => true, :within => 8..40
  
  scope :alive,   where("flag != 1 or flag is null")
  scope :deleted, where("flag = 1")
  
  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessor :password
  #attr_accessible :login, :email, :name, :password, :password_confirmation
  attr_accessible :login, :password, :password_confirmation, :display_name, :group_id, :permission_id, :state, :sex, :type, :cti_agent_id, :role_id, :external_user_name, :email, :id_card, :flag

  acts_as_state_machine :initial => :pending
  state :passive
  state :pending, :enter => :make_activation_code
  state :active,  :enter => :do_activate
  state :suspended
  state :deleted, :enter => :do_delete

  event :register do
     transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
  end

  event :activate do
     transitions :from => :pending, :to => :active
  end

  event :suspend do
     transitions :from => [:passive, :pending, :active], :to => :suspended
  end

  event :delete do
      transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
  end

  event :unsuspend do
      transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank? }
      transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? }
      transitions :from => :suspended, :to => :passive
  end

  def make_activation_code
     self.deleted_at = nil
     self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  def do_delete
     self.deleted_at = Time.now.utc
  end

  def do_activate
     @activated = true
     self.activated_at = Time.now.utc
     self.deleted_at = self.activation_code = nil
  end   

  @@label_sex = { 'U' => "Undefined", 'F' => "Female", 'M' => "Male",'u' => "Undefine", 'f' => "Female", 'm' => "Male" }
  @@msg_template = "username are expired."
   
  def reset_password(password)
    
    pass = password
    comf_pass = pass
    
    self.update_attributes({:password => pass, :password_confirmation => comf_pass})
    
    return true  
  end
   
  def self.sex_symbol(sex_label)
    return @@label_sex.index(sex_label) rescue 'u'
  end
  
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_in_state :first, :active, :conditions => {:login => login.downcase} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
   
   def self.error_msg
       @@msg_template
   end
   
  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

   def sex2
      @@label_sex[self.sex]
   end 
   
   def state_name
     return (self.state == 'pending' or self.state == 'passive') ? 'Inactive' : 'Active' 
   end
   
   def is_expired_date?
     if self.expired_date.nil?
       return false
     else
       if Time.new >= Time.parse(self.expired_date)
         return true
       else
         return false
       end
     end
   end
   
   def id_card2
     return (self.id_card.to_s.gsub(/(\d)(\d{4})(\d{5})(\d{2})(\d)/,"\\1-\\2-\\3-\\4-\\5"))
   end
   
   def role_name
     
     return (self.role.nil? ? nil : self.role.name)
      
   end

   def extensions_list
     eams = ExtensionToAgentMap.where(:agent_id => self.id).group('extension').order('extension asc').all
     @@extensions_list = eams.map { |m| m.extension }
   end
   
   def phones_list
     dams = DidAgentMap.where(:agent_id => self.id).group('number').order('number asc').all
     @@phones_list = dams.map { |m| m.number } 
   end
      
   protected
   
end
