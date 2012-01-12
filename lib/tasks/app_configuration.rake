namespace :application do

  desc 'Setup configurations'
  task :configuration => :setup do
    
    Rake::Task['application:configuration:remove'].invoke
    Rake::Task['application:configuration:create'].invoke

  end

  namespace :configuration do

     desc 'Create configurations'
     task :create => :setup do
        create_configuration
     end

     desc 'Remove configurations'
     task :remove => :setup do
        remove_configuration
     end

     desc 'update configurations'
     task :update => :setup do
        create_configuration
     end

  end

end

def create_configuration

  STDERR.puts "--> Creating configurations ..."
  
  configuration_file = "CONFIGURATIONS.txt"
  configuration_file = File.join(File.dirname(__FILE__),configuration_file)

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

            STDERR.puts "NEW : #{current_config_type_id},#{current_config_group},#{name},#{type}"
            
            cf = Configuration.new({
                  :configuration_group_id => current_config_group_id,
                  :variable => name,
                  :variable_type => type,
                  :default_value => default,
                  :description => desc}).save
            
          else

            STDERR.puts "UPD : #{current_config_type_id},#{current_config_group},#{name},#{type}"

            cf = Configuration.find(:first,:conditions => {:configuration_group_id => current_config_group_id,:variable => name})
            new_cf = {
                  :variable => name,
                  :variable_type => type,
                  :default_value => default,
                  :description => desc}
            
            Configuration.update(cf.id,new_cf)
            
          end

        end
        
      end

      STDERR.puts "--> Create configurations are successfully."
    else
      STDERR.puts "--> Configurations file not found."
    end

  rescue => e
    STDERR.puts "--> Creating configurations are failed. [#{e.message}]"
  end

end

def remove_configuration
  
  STDERR.puts "--> Removing configurations ..."
  
  begin
    Configuration.delete_all()
    ConfigurationGroup.delete_all()
    ConfigurationData.delete_all()
    STDERR.puts "--> Remove configurations are successfully."
  rescue => e
    STDERR.puts "--> Remove configurations are failed. [#{e.message}]"
  end
  
end