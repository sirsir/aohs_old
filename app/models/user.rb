# == Schema Information
# Schema version: 20100402074157
#
# Table name: users
#
#  id                        :integer(11)     not null, primary key
#  login                     :string(255)
#  email                     :string(255)
#  crypted_password          :string(40)
#  salt                      :string(40)
#  created_at                :datetime
#  updated_at                :datetime
#  remember_token            :string(255)
#  remember_token_expires_at :datetime
#  activation_code           :string(40)
#  activated_at              :datetime
#  state                     :string(255)     default("passive")
#  deleted_at                :datetime
#  display_name              :string(255)
#  type                      :string(255)
#  group_id                  :integer(10)     default(0), not null
#  lock_version              :integer(10)
#  role_id                   :integer(10)     default(0), not null
#  sex                       :string(1)       default("u"), not null
#  expired_date              :datetime
#  flag                      :boolean(1)
#  cti_agent_id              :integer(10)
#

require 'digest/sha1'
class User < ActiveRecord::Base

   belongs_to :group, :class_name => 'Group',  :foreign_key => 'group_id'
   belongs_to :role,  :class_name => 'Role',   :foreign_key => 'role_id'

   belongs_to :configurationData
   has_many :configurations, :through => "ConigurationData"
     
   # Virtual attribute for the unencrypted password
   attr_accessor :password
   
   validates_presence_of     :login
   validates_presence_of     :password,                   :if => :password_required?
   validates_presence_of     :password_confirmation,      :if => :password_required?
   validates_length_of       :password, :within => 6..40, :if => :password_required?
   validates_confirmation_of :password,                   :if => :password_required?
   validates_length_of       :login,    :within => 4..40
   validates_uniqueness_of   :login, :case_sensitive => false, :scope => :flag
   validates_presence_of     :type

   before_save :encrypt_password
   
   #  attr_accessible :login, :email, :password, :password_confirmation
   attr_accessible :login, :password, :password_confirmation, :display_name, :group_id, :permission_id, :sex, :type, :cti_agent_id, :role_id, :external_user_name, :email, :id_card

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

   def self.find(*args)
      options = args[1]
    unless options.blank?
    unless options.has_key?(:showAll)
    with_scope(:find=>{:conditions=>"flag != 1 or flag is null" }) do
        super(*args)
        end
     
    else
      super(*args)
    end
    else
      super(*args)
    end
   end

   # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
   def self.authenticate(login, password)
      u = find_in_state :first, :active, :conditions => {:login => login} # need to get the salt
     # u && u.authenticated?(password) ? u : nil original code
     if u && u.authenticated?(password)
       unless u.expired_date.nil?
       if u.expired_date > Date.today
          return u
       else
          @@msg_template = "Login Fails. username is expired."
          return nil
       end
       else
         return u
       end
     else
       @@msg_template = "Login Fails.username/password incorrect or not activated."
       return nil
     end
   end

   # Encrypts some data with the salt.
   def self.encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
   end

   # Encrypts the password with the user salt
   def encrypt(password)
      self.class.encrypt(password, salt)
   end

   def authenticated?(password)
      crypted_password == encrypt(password)
   end
 
   def remember_token?
      remember_token_expires_at && Time.now.utc < remember_token_expires_at
   end

   # These create and unset the fields required for remembering users between browser closes
   def remember_me
      remember_me_for 2.weeks
   end

   def remember_me_for(time)
      remember_me_until time.from_now.utc
   end

   def remember_me_until(time)
      self.remember_token_expires_at = time
      #    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
      self.remember_token            = encrypt("#{login}--#{remember_token_expires_at}")
      save(false)
   end

   def forget_me
      self.remember_token_expires_at = nil
      self.remember_token            = nil
      save(false)
   end

   # Returns true if the user has just been activated.
   def recently_activated?
      @activated
   end

   # yamamoto added
   def reset_password(password)
      if password.length >= 6
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--")
      self.crypted_password = encrypt(password)
      return true
      else
      return false
      end
   end

   protected
   # before filter
   def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
   end

   def password_required?
      crypted_password.blank? || !password.blank?
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

   @@label_sex = { 'U'=>"Undefine", 'F'=>"Female", 'M'=>"Male",'u'=>"Undefine", 'f'=>"Female", 'm'=>"Male" }
   @@msg_template = "username are expired."

   def self.error_msg
       @@msg_template
   end
public
   def sex2
      @@label_sex[self.sex]
   end
   
   def state_name
     return (self.state == 'pending' or self.state == 'passive') ? 'Inactive' : 'Active' 
   end
   
   def id_card2
     return (self.id_card.to_s.gsub(/(\d)(\d{4})(\d{5})(\d{2})(\d)/,"\\1-\\2-\\3-\\4-\\5"))
   end
   
   def role_name
     
     return (self.role.nil? ? nil : self.role.name)
      
   end

   def extensions_list
     eams = ExtensionToAgentMap.find(:all, :conditions => {:agent_id => self.id}, :group => :extension, :order => "extension asc")
     @@extensions_list = eams.map { |m| m.extension }
   end

   def phones_list
     dams = DidAgentMap.find(:all, :conditions => {:agent_id => self.id}, :group => :number, :order => "number asc")
     @@phones_list = dams.map { |m| m.number }
   end 
   
end
