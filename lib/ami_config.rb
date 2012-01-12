require 'yaml'

module AmiConfig

  MIMETYPE_CSV = "application/csv"
  MIMETYPE_PDF = "application/pdf"
  MIMETYPE_TXT = "text/plain"
      
  def self.set_user(user_id)
     @@user = User.find(user_id)
  end
  
  def self.get(key)

    # key
    # format : type.group.variable

    cf_value = nil

    begin
      
      cf_str = key.strip.split(".")
      cf_type = cf_str[0].split("").first.upcase

      cf = Configuration.find(:first,
                              :include => :configuration_group,
                              :conditions => {
                                      :configuration_groups => {:configuration_type => cf_type,:name => cf_str[1]},
                                      :variable => cf_str[2]})

      conditions = []
      if defined? @@user and not @@user.nil?
        if @@user.group_id.to_i > 0
          conditions << "((configuration_datas.config_type = 0 and configuration_datas.config_type_id is null) or (configuration_datas.config_type = 1 and configuration_datas.config_type_id = #{@@user.group_id.to_i}) or (configuration_datas.config_type = 2 and configuration_datas.config_type_id = #{@@user.id}))"
        else
          conditions << "((configuration_datas.config_type = 0 and configuration_datas.config_type_id is null) or (configuration_datas.config_type = 2 and configuration_datas.config_type_id = #{@@user.id}))"
        end
      end   

      unless cf.nil?
        conditions << "configuration_datas.configuration_id = #{cf.id}"
        cfd = ConfigurationData.find(:all,:conditions => conditions.join(' and '),:order => 'configuration_id,config_type desc')
        unless cfd.empty?
          cfd.each do |x|
            cf_value = convert_type(x.value,cf.variable_type)
            break
          end
        else
          cf_value = convert_type(cf.default_value,cf.variable_type)
        end

        if cf_value.nil? or cf_value == "NULL" or cf_value == "null"
          cf_value = nil
        end
      end

    rescue => e
      STDERR.puts "Config:#{key} - #{e.message}"
      Rails.logger.error "Config:#{key} - #{e.message}"
    end

    cf_value
    
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

    @value
    
  end

  def self.set_database_configuration

    rails_env = "test" #"production"

    tmp_conn = "Server=127.0.0.1;Database=myDataBase;Uid=myUsername;Pwd=myPassword;Port=3306"

    STDOUT.puts tmp_conn
    unless tmp_conn.nil?

      tmp_conn = tmp_conn.split(';')

      unless tmp_conn.empty?

        mysql_cn = {}

        begin

            tmp_conn.each do |c|
                a = c.split("=")
                mysql_cn[a[0].to_s.downcase.to_sym] = a[1]
                STDOUT.puts "#{a[0].to_s.downcase}:#{a[1]}"
            end

            config = Rails::Configuration.new
            cf = YAML::load(IO.read(config.database_configuration_file))

            cf[rails_env]["host"] = mysql_cn[:server] if not mysql_cn[:server].nil? and not mysql_cn[:server].empty?
            cf[rails_env]["database"] = mysql_cn[:database] if not mysql_cn[:database].nil? and not mysql_cn[:database].empty?
            cf[rails_env]["username"] = mysql_cn[:uid] if not mysql_cn[:uid].nil? and not mysql_cn[:uid].empty?
            cf[rails_env]["password"] = mysql_cn[:pwd] if not mysql_cn[:pwd].nil? and not mysql_cn[:pwd].empty?
            cf[rails_env]["port"] = mysql_cn[:port] if not mysql_cn[:port].nil? and not mysql_cn[:port].empty?

            File.open(config.database_configuration_file, 'w') { |f| YAML.dump(cf, f) }

        rescue => e
            STDERR.puts "set_database_configuration:#{e.message}"
        end
        
      end
      
    end

  end

  def self.configurations_repair
  
    # AohsWeb
    
    STDOUT.puts "=> Checking system configuration"
    
    configuration_file = "CONFIGURATIONS.txt"
    configuration_file = File.join(RAILS_ROOT,'lib','tasks',configuration_file)
  
    begin
      if File.exist?(configuration_file)
  
        current_config_type = nil
        current_config_group = nil
        current_config_type_id = nil
        current_config_group_id = nil
        
        File.open(configuration_file).each do |line|
          next if line =~ /^#/
          next if line =~ /^$/
          next if line.blank?
  
          if line.strip =~ /^.+:\z/
  
            a = line.strip.split(".")
            current_config_type = a[0].strip
            current_config_group = a[1].strip.gsub(":","")
            case current_config_type
              when "server"
                current_config_type_id = "S"
              when "client"
                current_config_type_id = "C"
            end
  
            if not ConfigurationGroup.exists?({:name => current_config_group, :configuration_type => current_config_type_id})
              cfg = ConfigurationGroup.new({:name => current_config_group, :configuration_type => current_config_type_id}).save
              cfg = ConfigurationGroup.find(:first,:conditions => {:name => current_config_group, :configuration_type => current_config_type_id})
              current_config_group_id = cfg.id
            else
              cfg = ConfigurationGroup.find(:first,:conditions => {:name => current_config_group, :configuration_type => current_config_type_id})
              current_config_group_id = cfg.id
            end
            
            next line
          else
            name, desc, type, default = line.strip.split("\t")
  
            default = default.gsub(/["|']/,"")
            desc = desc.gsub(/["|']/,"")
            
            if not Configuration.exists?({:configuration_group_id => current_config_group_id,:variable => name})
  
              AmiLog.linfo("[configurations-repair] - add =>#{current_config_type_id},#{current_config_group},#{name},#{type}")
              
              cf = Configuration.new({
                    :configuration_group_id => current_config_group_id,
                    :variable => name,
                    :variable_type => type,
                    :default_value => default,
                    :description => desc}).save
              
            end
  
          end
          
        end
          #AmiLog.linfo("[configurations-repair] - check successfully.")
      else
          #AmiLog.linfo("[configurations-repair] - file not found => #{File.join(RAILS_ROOT,'lib','tasks',configuration_file)}")
      end
  
    rescue => e
          AmiLog.linfo("[configurations-repair] - #{e.message}")
    end   
    
  end
  
end
