# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'logger'

module AmiLog

  ## ===== save log table ===== ##
  
  $APP_LOG_NAME = "AOHS"
  
  def get_user

    begin
       curr_user = current_user.login
    rescue
       curr_user = "UnknownUser"
    end

    return curr_user

  end
  
  def log(action_log="",target="",result=nil,message=nil,op={})

    usr = get_user

    unless op[:user].nil?
      usr = op[:user]
    end

    if not action_log.blank? and not target.blank?

      log_data = {
              :user => usr,
              :start_time => Time.new.strftime("%Y-%m-%d %H:%M:%S"),
              :name => action_log,
              :target => target,
              :remote_ip => request.remote_ip,
              :message => message,
              :application => $APP_LOG_NAME
          }

      str_status = nil
      case result
      when true,/0/:
        str_status = "Success"
      when false,/1/:
        str_status = "Failed"
      end

      log_data[:status] = str_status

      new_log = Logs.new(log_data)
      new_log.save

    end

  end

  def self.batch_log(action_log="",target="",result=nil,message=nil,op={})

      log_data = {
              :user => "System",
              :start_time => Time.new.strftime("%Y-%m-%d %H:%M:%S"),
              :name => action_log,
              :target => target,
              :remote_ip => "localhost",
              :message => message,
              :application => $APP_LOG_NAME
          }

      str_status = nil
      case result
      when true,/0/:
        str_status = "Success"
      when false,/1/:
        str_status = "Failed"
      end

      log_data[:status] = str_status

      new_log = Logs.new(log_data)
      new_log.save
    
  end
  
  ## ===== application.log ===== ##

  def self.set_flog

     $SCHLOG = Logger.new(File.join(RAILS_ROOT,'log','application.log'),'daily')
    
  end

  def self.linfo(str)

    if not defined?($SCHLOG)
      set_flog
    end
    
    strlog = "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{str}"
    STDOUT.puts strlog
    $SCHLOG.info strlog
        
  end

  def self.lerror(str)

    if not defined?($SCHLOG)
      set_flog
    end

    strlog = "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{str}"
    STDERR.puts strlog
    $SCHLOG.error strlog

  end

  ## ===== scheduler for logs ===== ##

  def self.auto_backup_log
    
    result = true
    msg = nil
    
    keep_days = Aohs::DAY_KEEP_LOGS #AmiConfig.get('client.aohs_web.keepLogDays').to_i
    
    if keep_days > 0

      begin

        delete_day = Date.today - keep_days
        
        logs = Logs.find(:all,:conditions => "start_time < '#{delete_day} 00:00:00'", :order => "start_time")
        f_count = 0
        f_rec = 0       
        logs_bak = {}
        
        unless logs.empty?
          logs.each do |l|
             xd = (l.start_time).strftime("%Y%m%d")
             if logs_bak["#{xd}"].nil?
                logs_bak["#{xd}"] = []
             end
             f_rec += 1
             logs_bak["#{xd}"] << [l.start_time.strftime("%Y/%m/%d %H:%M:%S"),l.name,l.status,l.target,l.user,l.remote_ip,"\"#{l.message}\""].join(", ")
          end
           
          logs_bak.each do |k,v|
            
            f_count += 1
            
            log_dir = File.join(RAILS_ROOT,'log')
            log_fname = "aohs_operation_log.log.#{k}"
            log_fpath = File.join(log_dir,log_fname)
            
            f = File.open(log_fpath,"a")
            v.each do |x|
              f.puts x + "\r\n"
            end
            f.close

            system "cd #{log_dir} && tar -cvf '#{log_fname}.tar' '#{log_fname}'"
            FileUtils.remove(log_fpath)
                        
          end

          logs = Logs.delete_all("start_time < '#{delete_day} 00:00:00'")

          logs = nil
          logs_bak = nil
          
          msg = "backup file=#{f_count} log_records=#{f_rec}, date=#{delete_day}"
          
          batch_log("Batch","Operation Log",true,"backup result: #{msg}")
        
        end
        
      rescue => e
          result = false
          msg = e.message
          batch_log("Batch","Operation Log",false,"backup result: #{msg}")
      end
          
    else
       #STOP
    end
    
  end

end
