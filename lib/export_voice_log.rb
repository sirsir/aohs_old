require 'fileutils'

module ExportVoiceLog

  DOCROOT = "/var/www/html/voicefiles"
  
  class ExecuteTask
    
    def self.run
      et = ExecuteTask.new
      et.run
    end
    
    ## Begin
    
    def initialize
      do_init
    end
    
    def run
      @tasks.each do |t|
        @logger.info "task id=#{t.id}, name=#{t.name}"
        
        if t.daily? and day_time?
          # skip if not night batch task
          @logger.info "skiped, wait for night batch."    
        end
        
        case true
        when t.expired?, t.deleted?, (t.finish_or_failure? and t.expired?)
          @logger.info "ok, removing task"
          vt = VoiceLogTask.new(t)
          vt.delete
        when t.wait_for_process?, t.failure?
          @logger.info "ok, exporting data"
          vt = VoiceLogTask.new(t)
          vt.export
        else
          @logger.info "unknown task state (#{t.flag}), plese check."
        end
      end
    end
    
    private
    
    def do_init
      @ps_time = Time.now
      logging
      find_tasks
    end
    
    def logging
      @logger = Logger.new(logfile_path)
      @logger.info "Starting process at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    end

    def logfile_path
      fname = "export.log.#{Time.now.strftime("%Y%m%d")}"
      fpath = File.join(Settings.server.directory.export_log, fname)
      return fpath
    end
    
    def find_tasks
      @tasks = []
      if no_task_inqueue?
        target_tasks = ExportTask.all
        target_tasks.each do |t|
          next if t.not_ready?
          @tasks << t
        end
      else
        @logger.info "Skip check task, found processing task in queue."
      end
      @logger.info "Found pending tasks in database, #{@tasks.length} tasks"
    end
    
    def no_task_inqueue?
      task_count = ExportTask.only_exporting.count(0)
      return task_count <= 0
    end
    
    def day_time?
      # export on day time
      # hour between 08 until 19
      return (now_hour >= 7 and now_hour <= 19)
    end
    
    def night_time?
      # export on night time
      # hour between 01 until 05
      return ((now_hour >= 1 and now_hour <= 5) or (now_hour >= 22))
    end
    
    def now_hour
      return Time.now.hour
    end
    
  end
  
  # class for process task
  
  class VoiceLogTask
    
    def initialize(task)
      @task = task
      do_logging
      do_start
    end

    def export
      @logger.info "trying to export data"
      unless @conditions.empty?
        @conditions.each do |c|
          sub_conds = c.conv_conditions
          sub_conds.each do |cond|
            @result[:cond_count] += 1
            @logger.info "trying export as condition ##{@result[:cond_count]}"
            @logger.info "Digest=#{cond[:digest]}"
            @logger.info "Condition=#{cond.inspect}"
            
            next if next_day?(cond)
            @result[:cond_processed] += 1
            next if not_proceed?(cond)
            
            result = get_result(get_sql(cond))
            update_export_result(cond, result)
          end
        end
      else
        @logger.warn "no conditions to process"
      end
      compress_directory
      remove_old_data
      update_task
    end
    
    def delete
      # delete directory and sub directory
      # and all files which is under this
      task_path = File.join(base_directory)
      if File.exists?(task_path) and File.directory?(task_path)
        FileUtils.rm_rf(task_path)
      end
      # delete in db
      # delete task and related data
      @task.do_permanent_delete
      @task.delete
    end
    
    def close
      # close task
      # change state back to wait.
      @task.set_state_finish(:wait)
    end
    
    private
  
    def do_start
      # init variables and prepare conditions
      @conditions = @task.export_conditions
      @result = {
        cond_count: 0, cond_succ: 0,
        cond_skip: 0, cond_failed: 0,
        cond_processed: 0
      }
      @task.set_state_processing
      @logger.info "trying to process task."
    end
    
    def do_logging
      # create log file per task
      fname = File.join(Settings.server.directory.export_log, @task.log_fname)
      @logger = Logger.new(fname)
    end
    
    def remove_old_data
      scn_dir = File.join(base_directory,"*")
      list = Dir.glob(scn_dir)
      list.each do |path|
        d = File.mtime(path)
      end
    end
  
    def next_day?(cond)
      if Date.parse(cond[:date]) > Date.today
        return true
      end
      return false
    end

    def not_proceed?(cond)
      is_proceed = true
      if @task.log_exist_and_success?(cond[:digest])
        is_proceed = false
      end
      return (not is_proceed)
    end
    
    def update_task
      if @result[:cond_processed] < @result[:cond_count]
        @task.set_state_finish(:wait)
      else
        if @result[:cond_failed] > 0
          @task.set_state_finish(:error)
        else
          @task.set_state_finish(:complete)
        end
      end
      @task.processed_at = Time.now
      @task.save
      @logger.info "result=#{@result.inspect}"
    end
    
    def get_sql(cond)
      cn = cond
      tv = VoiceLog.table_name
      tu = User.table_name
      select = select_fields
      where = []
      
      sql = []
      sql << "SELECT #{select.join(",")}"
      sql << "FROM #{tv} LEFT JOIN #{tu} ON #{tv}.agent_id = #{tu}.id"
      
      where << "start_time BETWEEN '#{cn[:date]} 00:00:00' AND '#{cn[:date]} 23:59:59'"
      
      unless cn[:times].nil?
        time_cond = []
        cn[:times].each do |time|
          if time[:hour_in].present?
            time_cond << "hour(start_time) IN (#{time[:hour_in]})"
          else
            time_cond << "hour(start_time) BETWEEN '#{time[:hour_from]}' AND '#{time[:hour_to]}'"
          end
        end
        where << "(#{time_cond.join(" OR ")})"
      end
      
      unless cn[:call_direction].nil?
        where << "call_direction = '#{cn[:call_direction]}'"
      end
      
      unless cn[:duration_from].nil?
        where << "duration >= '#{cn[:duration_from]}'"
      end

      unless cn[:duration_to].nil?
        where << "duration <= '#{cn[:duration_to]}'"
      end
      
      unless cn[:phones].empty?
        phones = (cn[:phones].map { |p| "'#{p}'" }).join(",")
        where << "(ani IN (#{phones}) OR dnis IN (#{phones}))"
      end
      
      sql << "WHERE #{where.join(" AND ")}"
      sql = sql.join(" ")
      
      @logger.info "SQL query: #{sql}"

      return sql

    end
    
    def select_fields
      vcols = [:id, :start_time, :ani, :dnis, :extension, :duration, :call_direction, :voice_file_url, :call_id].map { |c|
        "#{VoiceLog.table_name}.#{c}"
      }
      ucols = [:login].map { |c|
        "#{User.table_name}.#{c}"
      }
      return vcols.concat(ucols)
    end
    
    def get_result(sql)
      ret = {
        total: 0, success: 0,
        failed: 0, skip: 0,
        completed: false
      }
      result = ActiveRecord::Base.connection.select_all(sql)
      
      unless result.empty?
        ret[:total] = result.length
        result.each do |r|
          success = download_and_save(r)
          if success
            ret[:success] += 1
          else
            ret[:failed] += 1
          end
        end
      end

      ret[:completed] = true if ret[:failed] <= 0
      @logger.info "summary: #{ret.inspect}"

      return ret
    end
    
    def update_export_result(cond, result)
      # keep export result and summary
      log = @task.export_logs.find_by_digest(cond[:digest]).first
      
      if log.nil?
        log = {
          condition_string: cond,
          target_call_date: cond[:date],
          status: '', flag: '',
          digest_string: cond[:digest]
        }
        log = @task.export_logs.new(log)
      end

      log.status = (result[:completed] ? 'S' : 'F')
      log.result_string = result
      log.retry_count = log.retry_count.to_i + 1
      log.save
      
      if log.status == 'S'
        @result[:cond_succ] += 1
      else
        @result[:cond_failed] += 1
      end
    
    end
    
    def download_and_save(r)
      
      err = false
      furl = r["voice_file_url"]
      fext = File.extname(furl)
      fname = File.join(base_directory,@task.map_filename(r) + fext)
      fdir = File.dirname(fname)
      
      xdir = WorkingDir.make_dir(fdir)
      if File.exists?(fdir) and File.directory?(fdir)
        
        fout = WorkingNet.file_download(furl,fdir)
        
        if File.exists?(fout)
          @logger.debug "Downloaded #{furl} to #{fout}"
          
          cmd = "mv '#{fout}' '#{fname}'"
          system cmd
          if File.exists?(fname)
            @logger.debug "Renamed to #{fname}"
            begin
              FileConversion.audio_convert(@task.audio_format_sym, fname)
              if File.exists?(fname)
                File.delete(fname)
              end
            rescue => e
              STDERR.puts "Audio convert error"
              STDERR.puts e.message
            end
          end
        else
          @logger.debug "Failed to download #{furl}"
          err = true
        end
        
      else
        @logger.error "No directory #{fdir}"
        err = true
      end

      return !err
    
    end
    
    def base_directory
      dir_root = Settings.server.directory.call_export
      dir_root = DOCROOT if dir_root.to_s.length <= 1
      return File.join(dir_root,@task.directory_name)
    end
    
    def compress_directory
      
      target_dir = base_directory
      if File.exists?(target_dir)
        
        dirs = Dir.glob(File.join(target_dir,"*"))
        dirs.each do |dir|
          
          next unless File.directory?(dir)
        
          dest_dir = dir.split("/").last
          cmd = nil
          @logger.info "Compressing #{dir} as #{@task.compression_method}"
          
          case @task.compression_method
          when "7zip"
            fname = "#{dest_dir}.7z"
            cmd = "cd '#{target_dir}' && 7za a #{fname} ./#{dest_dir}"   
          when "gz"
            fname = "#{dest_dir}.tar.gz"
            cmd = "cd '#{target_dir}' && tar -zcvf #{fname} ./#{dest_dir}"          
          when "bz2"
            fname = "#{dest_dir}.tar.bz2"
            cmd = "cd '#{target_dir}' && tar -jcvf #{fname} ./#{dest_dir}"  
          when "tar"
            fname = "#{dest_dir}.tar"
            cmd = "cd '#{target_dir}' && tar -cvf #{fname} ./#{dest_dir}" 
          when "zip"
            fname = "#{dest_dir}.zip"
            cmd = "cd '#{target_dir}' && zip -r #{fname} ./#{dest_dir}" 
          end
          
          unless cmd.nil?
            system cmd
          end

        end
        
      end
    
    end
      
  end
end
