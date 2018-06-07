class MakeVoiceLog
  
  def self.make_log(d)
    
    @voicefiles = []
    
    number_of_extensions = 60
    
    destination_info
    set_auto_increment_id
    prepare_file_lists
    
    call_date = d
    exts = Extension.order("id").limit(number_of_extensions).all.to_a
    users = User.not_deleted.limit(exts.length).order("id").all
    unkn_exts = exts.sample(5)
    
    tt_calls    = 0
    idx         = 0
    
    users.each do |u|
      
      t1    = 0
      t2    = Time.now
      d,tt  = get_last_log(u,call_date)
      ext   = exts.shift
      dids  = ext.dids.map { |d| d.number} 
      stime = d + rnd_timegap
      idx += 1
      
      STDOUT.puts "Making call transactions for #{u.login} on #{d}"
      STDOUT.puts " -> Extension #{ext.number}, #{dids.join(',')}, #{idx}/#{users.length}"
      
      while (stime.strftime("%H").to_i <= 17)
        
        vfile = @voicefiles.sample
        site  = vfile[:site_id]
        sys   = vfile[:system_id]
        cd    = ['i','o'].sample
        
        if cd == 'o'
          ani  = dids.sample
          dnis = mk_phone(cd)
        else
          dnis = dids.sample
          ani  = mk_phone(cd)
        end
        
        duration = vfile[:duration]
        
        voice_log = {
          system_id:      sys,
          device_id:      (1..5).to_a.sample,
          channel_id:     (1..5).to_a.sample,
          hangup_cause:   nil,
          duration:       nil,
          ani:            ani,
          dnis:           dnis,  
          extension:      ext.number,
          call_reference: rand(10),
          agent_id:       u.id,
          voice_file_url: vfile[:url],
          call_direction: cd,
          start_time:     stime.strftime("%Y-%m-%d %H:%M:%S"),
          call_id:        mk_call_id(sys,stime),
          site_id:        site
        }
        
        # set unknown
        if unkn_exts.include?(voice_log[:extension])
          voice_log[:agent_id] = 0
        end

        voice_log = VoiceLogToday.new(voice_log.stringify_keys)
        
        # on connected
        voice_log.save!
        
        # on disconnected
        voice_log.hangup_cause = rand(10)
        voice_log.duration = duration
        voice_log.save!
        
        t1 += 1
        
        transfer_duration = 0
        #if voice_log.device_id == voice_log.channel_id
        #  transfer_duration = make_tranfer_call(voice_log)
        #end
        
        # next start_time
        stime = stime + duration + rnd_timegap + transfer_duration
        
        # lunch break
        stime = stime + (60 * 60) + rand(800) if stime.strftime("%H").to_i == 12
        
        hx = stime.strftime("%H").to_i
        mx = stime.strftime("%M").to_i
        break if hx >= 18
        
      end
      
      tt_calls = tt_calls + t1
      STDOUT.puts " -> Created #{t1} records in #{Time.now - t2} ms"

    end

    STDOUT.puts "Total created #{tt_calls} for #{users.length} users"
    
  end
  
  private
  
  def self.make_tranfer_call(vl)
    
    n_transfer  = [1,2].sample
    tt_duration = 0
    
    stime = vl.start_time + vl.duration.to_i
    
    n_transfer.times do |i|

      cd    = 'o'      
      if cd == 'o'
        ani  = vl.ani
        dnis = mk_phone(cd)
      else
        dnis = vl.dnis
        ani  = mk_phone(cd)
      end
      
      duration = rnd_duration
      duration += 1 if rand(10) >= 8
      
      voice_log = {
        system_id:      vl.system_id,
        device_id:      vl.device_id,
        channel_id:     vl.device_id,
        ani:            ani,
        dnis:           dnis,
        extension:      vl.extension,
        duration:       duration,
        hangup_cause:   rand(10),
        call_reference: rand(10),
        agent_id:       vl.agent_id,
        voice_file_url: rnd_voice_url,
        call_direction: cd,
        start_time:     stime,
        call_id:        "#{vl.call_id}00#{i}",
        site_id:        1,
        ori_call_id:    vl.call_id
      }
      
      stime = stime + duration
      tt_duration += duration

      voice_log = VoiceLogToday.new(voice_log)
      voice_log.save!
      
    end

    return tt_duration
  
  end
  
  def self.destination_info
    STDOUT.puts "Target class: #{VoiceLog.name}, table: #{VoiceLog.table_name}"
    STDOUT.puts "Target class: #{VoiceLogToday.name}, table: #{VoiceLogToday.table_name}"
  end
  
  def self.get_last_log(u,d)
    
    sel = "MAX(start_time) AS call_time, SUM(duration) AS sum_duration, COUNT(0) AS total"
    whs = ["agent_id = ? AND start_time BETWEEN ? AND ? ",u.id,d.strftime("%Y-%m-%d 00:00:00"),d.strftime("%Y-%m-%d 23:59:59")]
    
    v   = VoiceLog.select(sel).where(whs).first
    vt  = VoiceLogToday.select(sel).where(whs).first
    
    avg_duration = v.sum_duration.to_i/v.total.to_i rescue 0
    avg_duration = avg_duration + rnd_timegap
    
    if v.total.to_i > 0
      if vt.total.to_i <= 0 or (vt.total.to_i > 0 and v.call_time > vt.call_time)
        return [v.call_time + avg_duration,v.total]
      else
        return [vt.call_time + avg_duration,vt.total]
      end
    else
      if vt.total.to_i > 0
        return [vt.call_time + avg_duration,vt.total]
      end
    end
    
    return [Time.parse(d.strftime("%Y-%m-%d 09:00:00")),0]
    
  end

  def self.set_auto_increment_id
    v_max_id  = VoiceLog.select("MAX(id) AS max_id").first.max_id.to_i
    vt_max_id = VoiceLogToday.select("MAX(id) AS max_id").first.max_id.to_i
    max_id = [v_max_id,vt_max_id].max + 1
    ActiveRecord::Base.connection.execute("ALTER TABLE voice_logs AUTO_INCREMENT = #{max_id}")
    ActiveRecord::Base.connection.execute("ALTER TABLE voice_logs_today AUTO_INCREMENT = #{max_id}")
    STDOUT.puts "Updated auto increment to #{max_id}"
  end

  def self.mk_phone(cd)
    p = ['081049','091059','061069'].sample.concat(Faker::Number.number(4))
    if cd == 'o' and rand(20) == 2
      p = ['1133','1113'].sample
    end
    return p
  end

  def self.rnd_timegap
    a = rand(5) + rand(5) + rand(5)
    b = rand(180) + rand(90) + rand(45) + 35
    return ((a * 60) + b)
  end
  
  def self.mk_call_id(sys,stime)
    stime.strftime("#{sys}%Y%m%d%H%M%S#{Time.now.strftime("%L")}")
  end
  
  def self.prepare_file_lists
    srcf = File.join(Rails.root,"test/data","voicefiles.txt")
    File.open(srcf).each do |line|
      line = line.chomp.strip.gsub(/\t/," ")
      next if line.empty? or line =~ /^#/
      row = line.split(/ +/)
      @voicefiles << {
        site_id: row[0].to_i,
        system_id: row[1].to_i,
        url: row[2],
        duration: row[3].to_f
      }
    end
  end
  
end