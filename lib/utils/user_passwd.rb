module AppUtils
  
  # for reset user's password as default password
  # by reset options
  
  class UserPasswd
    
    def self.reset_user_password(options={})
      do_reset(options)
    end
    
    private
    
    def self.do_reset(options)
      users = find_users(options)
      unless users.empty?
        users.each do |u|
          u.reset_default_password
          if u.save
            STDOUT.puts "=> [ OK] #{u.login}"
          else
            STDOUT.puts "=> [ERR] #{u.login}, #{u.errors.full_messages}"
          end
        end
      end
    end
    
    def self.find_users(options)
      # finding list of users need to reset password
      STDOUT.puts "Finding users follow options: #{options.inspect}"
      
      user = User.not_deleted   
      case true
      when options[:all].present?
        return user.not_deleted.all
      when options[:role_id].present?
        return user.where(role_id: options[:role_id]).all
      when options[:user_id].present?
        return user.where(id: options[:user_id]).all
      when options[:nopassword].present?
        return user.no_password.all
      else
        STDOUT.puts "No select option"
        return []
      end
    end
    
    # end class
  end
end