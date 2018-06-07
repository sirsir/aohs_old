class MakeComputerLog
  
  def self.make_logs
    
    total_users = User.not_deleted.count
    
    users       = User.not_deleted.order("RAND()").limit((total_users/5)*4)  
    exts        = Extension.order("RAND()").all.to_a
    
    users.each do |u|
      
      ext = exts.shift
      
      begin
        cl = {
          check_time: Time.now,
          computer_name: ext.computer_info.computer_name,
          login_name: u.login,
          remote_ip: ext.computer_info.ip_address
        }
      rescue => e
        STDERR.puts e.message
      end
      
      cl = ComputerLog.new(cl)
      cl.save!
      
    end
    
  end

  private
  
end