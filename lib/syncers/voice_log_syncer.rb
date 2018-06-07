module DataSyncer
  module VoiceLogSyncer
    
    class VoiceLogUpdate
      
      def self.update(id,vo)  
        vlu = VoiceLogUpdate.new(id, vo)
        vlu.update
        return vlu.success?
      end
      
      def initialize(id, vo)
        @voice_log_id = id
        @vo = vo     
        @vl = nil
        @success = false
      end
      
      def update
        @vl = VoiceLog.where(["id = ?", @voice_log_id]).order(false).first
        if @vl.nil?
          insert_log if accept?
        else
          update_log
        end
        if @success
          update_call_type
          update_transfer
          if true
            update_usratl_map
          end
        end
      end
      
      def accept?
        # check garbage record
        # skip reason:
        # - zero duration
        # - monitor, delete flag
        if @vo.duration.to_i <= 0
          unless transfer_record?
            return false
          end
        end
        if hidden_flag?
          return false
        end
        return true
      end
      
      def update_transfer
        unless transfer_record?
          # recheck transfer record
          logs = VoiceLogToday.where(["ori_call_id = ?", @vo.call_id]).order(false).all.to_a
          unless logs.empty?
            logs.each do |log|
              upok = VoiceLogUpdate.update(log.id, log)
            end
          end
        end
      end
      
      def update_call_type
        # private call / personal call for outbound
        # lookup form numbers tables
        if true
          telnumber = nil
          if @vo.call_direction == 'o'
            telnumber = @vo.dnis
          else
            telnumber = @vo.ani
          end
          telobj = PhoneNumber.new(telnumber)
          telinfo = TelephoneInfo.find_number(telobj.real_number).only_private.first
          unless telinfo.nil?
            CallClassification.add_call_type(@vo.id, 'private')
          end
        end
      end
      
      def update_usratl_map
        begin
          unless @vo.nil?
            VoiceLogAtlusrMap.create_or_update(@vo)
          end
        rescue => e
        end
      end
      
      def hidden_flag?
        # d => deleted record
        # m => silence monitor record
        return ['m','d'].include?(@vo.flag.to_s)  
      end
      
      def file_url?
        begin
          if @vo.voice_file_url.to_s.length > 1
            return true
          end
        rescue
          return true
        end
        return false
      end
      
      def transfer_record?
        # this record is transfer record, not main record
        begin
          if @vo.ori_call_id.to_s.length > 1
            return true
          end
        rescue
        end
        return false
      end
      
      def success?
        # copy success?
        return true
      end
      
      def insert_fields(vl)
        ori_call_id = ""
        if defined? vl.ori_call_id
          ori_call_id = vl.ori_call_id.to_s
        end
        
        fields = {
          id:               vl.id,
          system_id:        vl.system_id.to_i,
          device_id:        vl.device_id.to_i,
          channel_id:       vl.channel_id.to_i,
          ani:              vl.ani,
          dnis:             vl.dnis,
          extension:        vl.extension,
          duration:         vl.duration.to_i,
          hangup_cause:     vl.hangup_cause.to_i,
          call_reference:   vl.call_reference.to_i,
          agent_id:         vl.agent_id.to_i,
          voice_file_url:   vl.voice_file_url.to_s,
          call_direction:   vl.call_direction,
          start_time:       vl.start_time,
          site_id:          vl.site_id.to_i,
          call_id:          vl.call_id,
          flag:             vl.flag,
          ori_call_id:      ori_call_id,
          call_date:        vl.start_time.strftime("%Y-%m-%d")
        }
        
        return fields
      end
      
      def insert_log
        fields = insert_fields(@vo)
        cols, vals = [], []
              
        fields.each do |k,v|
          cols << k.to_s
          vals << field_value(convert_val(v))
        end
        
        sql =  "INSERT INTO #{VoiceLog.table_name}(#{cols.join(",")}) "
        sql << "VALUES(#{vals.join(",")})"
        sql_exec(sql)
        @success = true
      end
      
      def update_fields
        fields = {}
        vo = @vo.attributes
        @vl.attributes.each do |k, v|
          next unless vo.has_key?(k)
          next if vo[k] == v 
          fields[k] = default_field_value(k,v)
        end
        return fields
      end
      
      def default_field_value(field_name, value)
        case field_name.to_sym
        when :site_id, :system_id, :channel_id, :device_id, :duration
          return value.to_i
        when :hangup_cause, :call_reference
          return value.to_i
        end
        return value
      end
      
      def field_value(v)
        if v.nil?
          return "NULL"
        end
        return "'#{v}'"
      end
      
      def update_log
        fields = update_fields
        cols = []
        
        unless fields.empty?
          fields.each do |k,v|
            cols << "#{k}=#{field_value(convert_val(v))}"
          end
          sql =  "UPDATE #{VoiceLog.table_name} "
          sql << "SET #{cols.join(", ")} "
          sql << "WHERE id = #{@vl.id} AND call_id = '#{@vl.call_id}'"
          sql_exec(sql)
        end
        
        @success = true
      end
  
      def convert_val(v)
        case true
        when v.is_a?(Date), v.is_a?(Time)
          return v.strftime("%Y-%m-%d %H:%M:%S")
        end
        return v
      end
      
      def sql_exec(sql)
        ActiveRecord::Base.connection.execute sql
      end
      
    end # end class
    
    #
    # To process call afer disconnected (hangup)
    # 1. Copy record from voice_logs_today to voice_logs
    # 2. Initial some field.
    #
    
    class HangupVoiceLog
      
      HANGUP_DURATION = 5
      
      def self.sync
        hc = HangupVoiceLog.new
        hc.run
      end
      
      def initialize  
        @ps_time = Time.now
        @total_count = 0
        @updated_count = 0
        @error_count = 0
      end
      
      def run
        # do process
        list = select_hangup
        list.all.each do |cl|
          to_voice_log(cl)
        end
        
        # write log
        message = [
          "total: #{@total_count}",
          "insert/update: #{@updated_count}",
          "error: #{@error_count}",
          "processing time: #{(Time.now - @ps_time).round(5)} secs"
        ].join(",")        
        ScheduleInfo.log("SYNC_HANGUP_CALL",{ message: message })
      end
      
      private
      
      def to_voice_log(cl)
        @total_count += 1
        vld = VoiceLogToday.where(["id = ?", cl.voice_log_id]).order(false).first
        unless vld.nil?
          success = VoiceLogUpdate.update(vld.id, vld)
          if success
            @updated_count += 1
          else
            @error_count += 1
          end
        else
          @error_count += 1
        end
        # remove it from hangup call that means already copied.
        cl.delete
      end
  
      def select_hangup
        cond = ["TIME_TO_SEC(TIMEDIFF(start_time,?)) <= ?", Time.now ,HANGUP_DURATION * -1]
        hc = HangupCall.where(cond)
        return hc
      end
      
      # end class
    end
    
    #
    # To repeat check sync at the end of day
    #
    
    class DailyLog
      
      SQL_NO_CACHE  = "SQL_NO_CACHE"
      
      def self.sync(opts={})  
        dl = DailyLog.new(opts)
        dl.sync
        dl.recheck
      end
      
      def self.sync_yesterday
        sync({ yesterday: true })
      end
  
      def initialize(opts={})
        # target date
        @ps_time = Time.now
        @ps_date = process_date(opts)
        @stime, @etime = compare_time_range
        @error_count = 0
        @total_count = 0
        @insert_count = 0
        @update_count = 0
      end
      
      def sync
        start_process
        save_log
        return true
      end
      
      def recheck
        result = get_voice_logs_detail
        result.each do |vl|
          success = VoiceLogUpdate.update(vl.id, vl)
        end
      end
      
      private
      
      def start_process
        result = get_voice_logs_today
        if @total_count > 0
          result.each do |vlt|
            update_record(vlt)
          end
          result = []
        end
      end
      
      def get_voice_logs_today
        selects = "#{SQL_NO_CACHE} id"
        
        conds = []
        conds << "start_time BETWEEN '#{@stime}' AND '#{@etime}'"
        
        vlt = VoiceLogToday.select(selects).where(conds.join(" AND "))
        
        result = ActiveRecord::Base.connection.select_all(vlt.to_sql)
        @total_count = result.length
        return result
      end
      
      def get_voice_logs_detail
        fields = [
          :id, :system_id, :device_id, :channel_id, :ani, :dnis, :extension, :duration,
          :hangup_cause, :call_reference, :agent_id, :voice_file_url, :call_direction,
          :start_time, :call_id, :site_id, :ori_call_id, :flag
        ]
        selects = "#{SQL_NO_CACHE} #{fields.join(",")}"
        
        conds = []
        conds << "start_time BETWEEN '#{@stime}' AND '#{@etime}'"
        
        result = VoiceLogDetail.select(selects).where(conds.join(" AND "))
        return result
      end
    
      def update_record(vlt)
        voice_log_id = vlt['id']
        temp = get_voice_log(VoiceLogToday, voice_log_id)
        perm = get_voice_log(VoiceLogDetail, voice_log_id)
  
        if temp.nil?
          return false
        end
        
        begin
          if perm.nil?
            insert_log(temp)
          else
            is_changed, diff = record_changed(temp,perm)
            if is_changed
              update_log(temp, diff)
            end
          end
          remove_temp_log(temp)
        rescue => e
          @error_count += 1
        end
        
      end
      
      def remove_temp_log(vl)
        sql = "DELETE FROM #{VoiceLogToday.table_name} WHERE id = '#{vl['id']}' AND call_id = '#{vl['call_id']}' LIMIT 1"
        exec_sql(sql)
      end
      
      def get_voice_log(md,id)
        sql = md.select("#{SQL_NO_CACHE} *").where(id: id).limit(1)
        result = ActiveRecord::Base.connection.select_all(sql.to_sql).first
        return result
      end
    
      def insert_log(vl)
        col = []
        val = []
        vl.each do |k,v|  
          next if v.nil?
          col << k
          val << "'#{convert_val(v)}'"
        end
        sql =  "INSERT INTO #{VoiceLogDetail.table_name}(#{col.join(",")}) "
        sql << "VALUES(#{val.join(",")})"
        exec_sql(sql)
        @insert_count += 1
      end
      
      def convert_val(v)
        case true
        when v.is_a?(Date), v.is_a?(Time)
          return v.strftime("%Y-%m-%d %H:%M:%S")
        else
          return v
        end
      end
      
      def record_changed(a, b)
        fields = {}
        a.each do |k,v|
          fields[k] = v if (a[k] != v)      
        end
        return (not fields.empty?), fields
      end
  
      def update_log(vl,fields)
        col = []
        fields.each do |k,v|
          col << "#{k}='#{convert_val(v)}'"
        end
        sql  = "UPDATE voice_logs_details "
        sql << "SET #{col.join(",")} WHERE id = #{vl['id']} AND call_id = '#{vl['call_id']}'"
        exec_sql(sql)
        @update_count += 1
      end
      
      def compare_time_range
        stime = @ps_date.beginning_of_day
        etime = @ps_date.end_of_day
        if etime >= Time.now
          etime = Time.now
        end
        return stime.to_formatted_s(:db), etime.to_formatted_s(:db)
      end
  
      def process_date(opt)
        if opt.has_key?(:yesterday)
          return Time.now - 1.day
        elsif opt.has_key?(:date)
          return parm_date(opt[:date])
        end
        return Time.now
      end
      
      def parm_date(d)
        return Time.parse(d.to_formatted_s(:db) + " 00:00:00")
      end
      
      def exec_sql(sql)
        return ActiveRecord::Base.connection.execute sql
      end
      
      def save_log
        message = [
          "date: #{@ps_date.to_date}",
          "total: #{@total_count}",
          "inserted: #{@insert_count}",
          "update: #{@update_count}",
          "error: #{@error_count}",
          "processing time: #{(Time.now - @ps_time).round(5)} secs"
        ].join(", ")
        ScheduleInfo.log("SYNC_VOICE_LOGS",{ message: message })
      end
      
    end # end class
  
  end
end
