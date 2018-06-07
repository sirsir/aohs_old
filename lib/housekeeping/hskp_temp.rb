module HousekeepingData
  class HskpTemp < Base
    
    def self.cleanup_temp_table
      ht = HskpTemp.new
      ht.cleanup_temp_table
    end
    
    def cleanup_temp_table
      @target_date = Date.today - 1
      cleanup_current_computer_status
      cleanup_current_channel_status
      cleanup_extension_map
    end
    
    private
    
    def cleanup_current_computer_status
      cond = "check_time <= '#{@target_date} 23:59:59'"
      CurrentComputerStatus.delete_all(cond)
      logger.info("Housekeeping data 'current_computer_status'")
    end
  
    def cleanup_current_channel_status
      cond = "start_time <= '#{@target_date} 23:59:59'"
      CurrentChannelStatus.delete_all(cond)
      logger.info("Housekeeping data 'current_channel_status'")
    end

    def cleanup_extension_map
      cond = "updated_at < '#{@target_date} 23:59:59'"
      uems = UserExtensionMap.where(cond).all
      uems.each do |uem|
        UserExtensionLog.create({
          log_date: uem.updated_at,
          extension: uem.extension,
          did: uem.did,
          agent_id: uem.agent_id
        })
      end
      UserExtensionMap.delete_all(cond)      
      logger.info("Housekeeping data 'user_extension_map'")
    end
    
    # end class
  end
end