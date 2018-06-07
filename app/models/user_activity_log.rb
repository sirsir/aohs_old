class UserActivityLog < ActiveRecord::Base
  
  CONTS_IDLE_TIME = "IDLE_TIME"
  
  scope :by_call_info, ->(user_id, start_time, end_time){
    # find cloest time first
    min_stime = by_user(user_id).before_start_time(start_time).maximum(:start_time)
    max_stime = by_user(user_id).after_end_time(end_time).minimum(:start_time)
    # do ..
    where(user_id: user_id).time_between(min_stime, max_stime).order_by_event
  }

  scope :time_between, ->(start_time, end_time){
    where(["start_time BETWEEN ? AND ?",start_time, end_time])  
  }
  
  scope :order_by_event, ->{
    order(start_time: :asc, proc_name: :asc)  
  }
  
  scope :before_start_time, ->(time,days=0){
    where(["start_time <= ?", time])
  }
  
  scope :after_end_time, ->(time,days=0){
    where(["start_time >= ?", time])  
  }
  
  scope :with_in_days, ->(d){
    where(["start_time >= ?", d.days.ago.beginning_of_day])  
  }
  
  scope :proc_list, ->{
    select("DISTINCT proc_exec_name, proc_name").where.not(proc_name: ['IDLE_TIME','__WATCHER__'])
  }
  
  scope :exclude_idle, ->{
    where.not({ proc_name: CONTS_IDLE_TIME })  
  }
  
  scope :not_zero_duration, ->{
    where("duration > 0")  
  }
  
  scope :by_user, ->(u){
    where(user_id: u)
  }
  
  def self.update_logs_from_watcher(result)
    
    ds = {
      login: result[:login],
      user_id: result[:user_id],
      remote_ip: result[:remote_ip],
      mac_addr: result[:mac]
    }

    unless result[:activities].empty?
      result[:activities].each do |rs|
        da = map_activity_field(rs)
        next if da[:proc_name].empty?
        write_to_es(da.merge(ds))
      end
    end
    
  end
  
  def self.update_idle_logs_from_watcher(result)
    
    ds = {
      login: result[:login],
      user_id: result[:user_id],
      remote_ip: result[:remote_ip],
      mac_addr: result[:mac]
    }
    
    unless result[:idles].empty?
      result[:idles].each do |rs|
        da = map_idle_field(rs)
        write_to_es(da.merge(ds))
      end
    end
    
  end
  
  def self.write_to_es(result)
    act_doc = ElsClient::ActivityLogDocument.new(result)
    act_doc.create
  end
  
  def self.result_logs(logs, v_stime, v_etime)

    # log must order by start_time
    
    pg_summ = []
    pg_list = []
    tt_duration = 0.0
    etime = v_stime
    stime = v_stime
    
    logs.each do |log|
      next if log.start_time + log.duration < v_stime
      next if log.start_time > v_etime
      
      # add idle time
      if log.start_time - etime > 0
        plen2 = log.start_time - etime
        etime2 = etime + plen2
        pg_list << { proc: 'idle', title: 'idle', stime: stime, etime: etime2, duration: plen2 }  
      end
      
      if log.start_time <= v_stime
        stime = v_stime
        plen = log.duration - (log.start_time - v_stime).abs 
      else
        stime = log.start_time
        if log.start_time + log.duration > v_etime
          plen = v_etime - stime
        else
          plen = log.duration
        end
      end
      etime = stime + plen

      p_idx = pg_summ.find_index { |x| x[:proc] == log.proc_exec_name }
      if p_idx.nil?
        detail = [{ title: log.window_title, duration: plen }]
        pg_summ << { proc: log.proc_exec_name, stime: stime, etime: etime, duration: plen, detail: detail }
      else
        pg_summ[p_idx][:duration] += plen
        pg_summ[p_idx][:etime] = etime
        pg_summ[p_idx][:detail] << { title: log.window_title, duration: plen }
      end
      tt_duration += plen.to_f
      pg_list << { proc: log.proc_exec_name, title: log.window_title, stime: stime, etime: etime, duration: plen }  
    end
    
    # add idle
    if v_etime - etime > 0 
      plen2 = v_etime - etime
      etime2 = etime + plen2
      stime = etime
      pg_list << { proc: 'idle', title: 'idle', stime: stime, etime: etime2, duration: plen2 }  
    end
    
    pg_summ.each do |pg|
      pg[:percentage] = pg[:duration].to_f/tt_duration*100
      pg[:duration_fmt] = StringFormat.format_sec(pg[:duration])
      p_info = ProgramInfo.get_info(pg[:proc])
      pg[:display_name] = p_info.name
      pg[:css] = p_info.css_content_class 
      pg[:detail] = pg[:detail].sort { |a, b| a[:duration] <=> b[:duration] }
      pg[:detail] = pg[:detail].reverse
      pg[:detail].each do |ps|
        ps[:duration_fmt] = StringFormat.format_sec(ps[:duration])
      end
    end
    pg_summ = pg_summ.sort { |a, b| a[:percentage] <=> b[:percentage] }
    
    pg_tmp = []
    pg_idx = -1
    pg_list.each do |pg|
      if pg_tmp.empty?
        pg_tmp << pg
        pg_idx = 0
      else
        if pg[:proc] == pg_tmp[pg_idx][:proc]
          pg_tmp[pg_idx][:duration] += pg[:duration]
          pg_tmp[pg_idx][:etime] = pg[:etime]
        else
          pg_tmp << pg
          pg_idx += 1
        end
      end
    end
    pg_list = pg_tmp
    
    spos = 0
    epos = 0
    pg_list.each do |pg|
      p_info = ProgramInfo.get_info(pg[:proc])
      pg[:display_name] = p_info.name
      pg[:css] = p_info.css_content_class
      pg[:spos] = spos 
      pg[:epos] = spos + pg[:duration]
      pg[:duration_fmt] = StringFormat.format_sec(pg[:duration])
      spos = spos + pg[:duration]
    end
    
    return {
      list: pg_list,
      summary: pg_summ.reverse
    }
    
  end

  private
  
  def self.map_activity_field(rs)
    
    pname = rs[2].to_s
    tname = rs[3].to_s
    pname2 = rs[4].to_s
    plength = rs[1].to_i
    
    # Fix duration zeron
    if plength == 0
      plength = 1
    end
    
    return {
      start_time: rs[0],
      duration: plength,
      proc_name: pname[0..100],
      window_title: tname[0..200],
      proc_exec_name: pname2[0..100]
    }
  
  end

  def self.map_idle_field(rs)
    
    return {
      start_time: rs[0],
      duration: rs[1].to_i,
      proc_name: CONTS_IDLE_TIME,
      window_title: CONTS_IDLE_TIME
    }
  
  end

end
