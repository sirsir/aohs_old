module AppUtils
  class DeleteEsDocument
    
    DELETE_BULK_SIZE = 2500
    DELAY_LOOP = 1
    
    def self.delete_docs(options={})
      ded = new(options)
      ded.perform_delete
    end
    
    def initialize(options)
      @options = init_options(options)
      @deleted_count = 0
    end
    
    def perform_delete
      find_and_delete
    end
    
    private
    
    def find_and_delete
      vdocs = build_delete_filter
      try_delete = true
      while try_delete
        vdocs = vdocs.only(:id).limit(DELETE_BULK_SIZE)
        docs = vdocs.to_a
        log "trying delete #{docs.length} records"
        docs.each do |doc|
          begin
            ddoc = ElsClient::VoiceLogDocument.new(doc.id)
            if ddoc.exists?
              ddoc.delete
              @deleted_count += 1
              break if exceed_limit?
            end
          rescue => e
            log e.message
          end
        end
        try_delete = false if docs.length <= 0 or exceed_limit?
        sleep DELAY_LOOP
      end
      log "total deleted #{@deleted_count} records"
      log "please run optimize tool to free spaces"
    end
    
    def build_delete_filter
      vdocs = VoiceLogsIndex::VoiceLog  
      
      # start-time
      st_date = @options[:date].strftime("%Y-%m-%d 00:00:00")
      ed_date = @options[:date].strftime("%Y-%m-%d 23:59:59")
      
      # ndays
      unless @options[:ndays].nil?
        ndays = @options[:ndays].to_i
        case true
        when ndays < 0
          st_date = Time.parse(st_date) + ndays.days
          st_date = st_date.strftime("%Y-%m-%d 00:00:00")
        when ndays > 0
          if ndays > 10
            STDOUT.puts "not allow ndays more than 10. Changed ndays to 10"
            ndays = 10
          end
          ed_date = Time.parse(ed_date) + ndays.days
          ed_date = ed_date.strftime("%Y-%m-%d 00:00:00")
        else
          STDOUT.puts "invalid ndays option, #{@options[:ndays]}"
        end
      end
      
      log "will delete document between '#{st_date}' and '#{ed_date}'"

      vdocs = vdocs.filter(range: { start_time: { gte: st_date, lte: ed_date, boost: 2 }})
      
      return vdocs
    end

    def exceed_limit?
      return (not @options[:limit].nil? and @deleted_count >= @options[:limit])   
    end
    
    def init_options(options)
      opts = options
      if options["date"].present?
        opts[:date] = Date.parse(options["date"])  
      end
      if options["limit"].present?
        opts[:limit] = options["limit"].to_i
      end
      return opts
    end
    
    def log msg
      STDOUT.puts msg  
    end
    
    # end class
  end
end