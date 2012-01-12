# == Schema Information
# Schema version: 20100402074157
#
# Table name: configurations
#
#  id                     :integer(11)     not null, primary key
#  variable               :string(255)
#  default_value          :string(255)
#  description            :string(255)
#  variable_type          :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  configuration_group_id :integer(10)
#

require 'yaml'

class Configuration < ActiveRecord::Base

   has_one :configuration_data , :foreign_key => "configuration_id"
   belongs_to :configuration_group, :foreign_key => "configuration_group_id"

   validates_length_of       :variable,    :within => 4..100
   validates_length_of       :variable_type,    :within => 4..255
   validates_uniqueness_of   :variable , :scope => [:configuration_group_id]
   
   after_update :after_update_configurations

	def after_update_configurations

    old_val = self.default_value_was
    new_val = self.default_value

    if old_val != new_val

      config = Configuration.find :first,
                                  :select => :variable,
                                  :conditions => {:default_value => new_val}

      case config.variable
      when "mysqlDbConnectionString"

        #Environment
        environment = ['development', 'test', 'production']

        #New Value
        # => '0' -> 'host'
        # => '1' -> 'database'
        # => '2' -> 'username'
        # => '3' -> 'password'
        # => '4' -> 'port'
        new_yml = new_val.split(';').collect {|x| x.split('=')[1]}

        #Read File 'database.yml'
        db_yml = YAML.load_file File.join(RAILS_ROOT,'config','database.yml')

        environment.each do |env|
          db_yml[env]['database'] = new_yml[1]
          db_yml[env]['host'] = new_yml[0]
          db_yml[env]['port'] = new_yml[4].to_i
          db_yml[env]['username'] = new_yml[2]
          db_yml[env]['password'] = new_yml[3]
        end

        File.open(File.join(RAILS_ROOT,'config','database.yml'),'w') {|f| YAML.dump(db_yml, f)}
        
      when "activeCheckerPath"
        set_yml = YAML.load_file File.join(RAILS_ROOT,'config','setting.yml')
        set_yml['config']['vl_checker_fpath'] = new_val

        File.open(File.join(RAILS_ROOT,'config','setting.yml'),'w') {|f| YAML.dump(set_yml, f)}
      
      end #End case

    end #End if
                              

  end
  
  def self.convert_type(value,value_type)

      type_name, value_ranges = value_type.split(/[\[\]]/)
      case value_ranges
      when /^(\d+)\.\.\.?(\d+)$/
        @valid_range = ($1.to_i)..($2.to_i)
      when /,/
        @valid_data_list = value_ranges.split(',')
      else
        # [FIXME] should be logged
        @valid_range = nil
        @valid_data_list = nil
      end

      case type_name
      when "string"
        @value_type = "string"
        @value = value.to_s
      when "integer"
        @value_type = "integer"
        @value = value.to_i
      when "boolean"
        @value_type = "boolean"
        if value =~ /^t/i
          @value = true
        else
          @value = false
        end
      else
       # [FIXME] should be logged
       @value_type = nil
       @value = nil
      end

      return @value
    end
    
   # ball commment

  #has_many :users, :through => "ConfigurationData"
   #has_many :groups, :through => "ConfigurationData"



=begin
   # ======== cannot get current_user ======== #

   attr_reader :value_type, :value

   def self.[] (key,user=nil)
      
      # key
      # format : type.group.variable
     
      cf_value = nil

      cf_str = key.strip.split(".")

      cf_type = cf_str[0].split("").first.upcase
      
      cf = Configuration.find(:first,
                              :include => :configuration_group,
                              :conditions => {
                                      :configuration_type => cf_type,
                                      :configuration_groups => {:name => cf_str[1]},
                                      :variable => cf_str[2]})

      unless $APPUSER.nil?
        group_id =  $APPUSER.group_id
        user_id = $APPUSER.id
      else
        group_id =  nil
        user_id = nil
      end

      
      unless cf.nil?

        cfd = ConfigurationData.find(:all,:conditions => {
                :configuration_id => cf.id,
                :config_type_id => [user_id,group_id].compact},
                :order => 'config_type desc')

        if not cfd.blank? and cf_type == "C"
          cfd.each do |c|
            unless c.nil?
              convert_type(cf.value,cf.variable_type)
              cf_value = c.value
              break
            end
          end
        else
          cf_value = cf.value
        end
        
      end

      cf_value

   end

   def convert_type(value,vtype)

     type_name, value_ranges = vtype.split(/[\[\]]/)

     case value_ranges
      when /^(\d+)\.\.\.?(\d+)$/
         @valid_range = ($1.to_i)..($2.to_i)
      when /,/
         @valid_data_list = value_ranges.split(',')
      else
         # [FIXME] should be logged
         @valid_range = nil
         @valid_data_list = nil
      end

      case type_name
      when "string"
         @value_type = "string"
         @value = self.default_value
      when "integer"
         @value_type = "integer"
         @value = self.default_value.to_i
      when "boolean"
         @value_type = "boolean"
         if self.default_value =~ /^t/i
            @value = true
         else
            @value = false
         end
      else
         # [FIXME] should be logged
         @value_type = nil
         @value = nil
      end

   end
=end

end

#__END__
#   hk.transaction.keep_period.voice_logs.statistics.begining_of_month
