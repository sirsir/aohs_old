module AppUtils
  
  # class for rotate any log files in log directory
  # <rails-root>/log/*.log

  class LogRotation
    
    def self.run
      prepare_script_file
      exec_rotate
    end

    private
    
    def self.exec_rotate
      system logrotate_cmd
    end
    
    def self.prepare_script_file
      # template
      template = Tilt.new(template_config_file)
      # target log files 
      pathname = File.join(Rails.root,"log","*.log")
      begin
        conf = File.new(script_file, "w")
        conf.puts template.render("",{ log_directory: pathname})
        conf.close
      rescue => e
        STDERR.puts "Error to create rotate file to #{conf_file}"  
      end
    end
    
    def self.script_file
      return File.join(Rails.root,'tmp','aohslogrotate')
    end
    
    def self.stat_file
      return File.join(Rails.root,'tmp','aohslog.status')  
    end
    
    def self.template_config_file
      return File.join(File.dirname(File.expand_path(__FILE__)).gsub("/utils",""),"templates","logrotate.conf.erb")
    end
    
    def self.logrotate_cmd
      return "logrotate #{script_file} --state #{stat_file}"
    end

    # end class
  end  
end

