
module AmiUser
  
  def self.create_admin_account
  
      # admin user
      STDERR.puts "--> Creating admin account ..."
  
      role_id = Role.find(:first,:conditions => {:name => 'Administrator'}).id
      
      admins = [
        { :login => 'AohsAdmin', :password => Aohs::ADMIN_PASSWORD, :password_confirmation => Aohs::ADMIN_PASSWORD, :display_name => 'AohsWeb Admin', :group_id => 0, :sex => 'u', :role_id => role_id }
      ]
      
      admins.each do |admin|
        unless Manager.exists?(admin[:login])
          xadmin = Manager.new(admin)
          xadmin.save(false)
          xadmin.activate!
          STDERR.puts "--> Creating admin [#{xadmin.login}] user successfully"
        else
          STDERR.puts "--> Creating admin [#{admin[:login]}] already exist"
        end 
      end
    
  end  
  
end