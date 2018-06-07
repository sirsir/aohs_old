require 'logger'

module SysLogger
  
  module ActionLog
    
    def db_log(mo_obj,event_name,message="")
      
      ol = OperationLog.new
      
      ol.log_type     = OperationLog::TYPES[:info]
      ol.module_name  = mo_obj.class.name
      ol.created_by   = ""
      ol.event_type   = "other"
      #ol.log_detail   = see in versions for more details
      
      ol.target_id, ol.target_name = target_info(mo_obj)     
      
      case event_name
      when :create, :new
        ol.event_type = "add"
        ol.message    = new_m(ol)
      when :edit, :update, :change
        ol.event_type = "update"
        ol.message    = update_m(ol)
      when :delete, :remove, :destroy
        ol.event_type = "delete"
        ol.message    = delete_m(ol)
      else
        #[nothing]
      end
      
      if not message.nil? and not message.empty?
        ol.message = message
      end
      
      if current_user and not current_user.nil?
        ol.created_by = current_user.login
      end
      
      if request and not request.nil?
        ol.remote_ip = request.remote_ip
      end
      
      ol.save
      
    end
  
    def db_error
      
    end
    
    def db_warn
      
    end
    
    private
    
    def target_info(mo_obj)
      
      target_id   = 0
      target_name = "The record"
      
      target_id = mo_obj.id
      if defined? mo_obj.name
        target_name = mo_obj.name
      elsif defined? mo_obj.login
        target_name = mo_obj.login
      elsif defined? mo_obj.title
        target_name = mo_obj.title
      else
        #[nothing]
      end
      
      return target_id, target_name
    
    end
    
    def new_m(ol)
      
      return "Inserted #{ol.target_name} "
    
    end
    
    def update_m(ol)
      
      return "Changed information for #{ol.target_name} "
    
    end
    
    def delete_m(ol)
      
      return "Deleted #{ol.target_name} "
    
    end
    
    def attr_changed_s(mo_obj)
    
      return nil
    
    end
    
  end
  
  # logging
  
  class << self
    def logger
      @logger ||= Logger.new(File.join(Rails.root,"log","maintenance.log"),"daily")
    end
    
    def formatter(severity, datetime, progname, msg)
      "#{datetime}:= #{msg}\n"
    end
  end
  
  #
  # extended module for manage logging sciprt
  # include this moudle for logging
  #
  
  module ScriptLogger
    def set_logger_path(ldir_path)
      @logger_filename = File.basename(ldir_path)
      @logger_directory_path = File.dirname(ldir_path)
    end
    
    def logger
      tnow      = Time.now.strftime("%Y%m%d")
      log_fname = @logger_filename + ".#{tnow}"
      wdir      = WorkingDir.make_dir(File.join(Settings.server.directory.log, @logger_directory_path))
      @logger ||= Logger.new(File.join(wdir,log_fname),"daily")
    end
    
    def formatter(severity, datetime, progname, msg)
      "#{datetime}:= #{msg}\n"
    end
  end
  
end