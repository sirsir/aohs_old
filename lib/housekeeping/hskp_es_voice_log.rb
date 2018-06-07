module HousekeepingData
  class HskpEsVoiceLog < Base
    
    NDAYS_CHECK = 5
    
    def self.run(options)
      ev = new(options)
      ev.delete_data
    end
    
    def delete_data
      d_date, ndays = target_date_to_delete
      opts = {
        "date"  => d_date,
        "ndays" => ndays.to_s
      }
      logger.info "target delete: #{opts.inspect}"
      opts = AppUtils::ThorOptionParser.parse(opts)
      AppUtils::DeleteEsDocument.delete_docs(opts.options)
    end
    
    private

    def target_date_to_delete
      keep_days = Settings.logs.trsdocs_keep_days
      if keep_days <= 20
        keep_days = 20
      end
      d = @options[:today] - keep_days  
      unless @options[:target_date].blank?
        d = @options[:target_date]
        return d.strftime("%Y-%m-%d"), nil
      end
      return d.strftime("%Y-%m-%d"), (NDAYS_CHECK*-1)
    end
    
  end
end