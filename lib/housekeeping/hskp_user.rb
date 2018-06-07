module HousekeepingData
  class HskpUser < Base
    
    def self.check_users  
      hu = HskpUser.new
      hu.auto_delete_inactive_user
    end
    
    def auto_delete_inactive_user  
      logger.info("Housekeeping data 'users' inactive users")
      inactive_users = User.only_inactive.all
      inactive_users.each do |user|
        if (Date.today - user.updated_at.to_date) > 90
          if user.do_delete and user.save
            logger.info("mask deleted to '#{user.id}':'#{user.login}'")
          end
        end
      end
    end
    
    # end class
  end
end