module HousekeepingData
  class HskpLogs < Base
    
    def self.cleanup_table_logs
      hl = HskpLogs.new
      hl.cleanup_table_logs
    end
    
    def cleanup_table_logs
      cleanup_computer_logs
      cleanup_operation_logs
      cleanup_display_logs
      cleanup_xfer_logs
    end

    def cleanup_computer_logs
      d_date = target_del_date
      cond = "check_time <= '#{d_date}'"
      ComputerLog.delete_all(cond)
      logger.info("Housekeeping Task for computer_logs removed logs before #{d_date}")
    end
    
    def cleanup_operation_logs
      d_date = target_del_date
      cond = "created_at <= '#{d_date}'"
      OperationLog.delete_all(cond)
      logger.info("Housekeeping Task for operation_logs removed logs before #{d_date}")
    end

    def cleanup_display_logs
      d_date = target_del_date
      cond = "display_time <= '#{d_date}'"
      DisplayLog.delete_all(cond)
      logger.info("Housekeeping Task for display_logs removed logs before #{d_date}")
    end

    def cleanup_xfer_logs  
      d_date = target_del_date
      logger.info("Housekeeping Task for xfer_logs removed logs before #{d_date}")
    end
    
    private
    
    def target_del_date
      return Date.today - Settings.logs.general_log_days.to_i
    end
    
  end
end