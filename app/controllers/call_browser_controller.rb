class CallBrowserController < ApplicationController

  before_filter :login_required, :except => [
                                      :get_info,
                                      :get_current_channels_status,
                                      :get_prvious_call,
                                      :call_stat,
                                      :search_voice_log,
                                      :get_destination_agent ]

  include AmiCallSearch
  
  layout 'call_browser'

  @@keyword_available = Aohs::MOD_KEYWORDS
  @@call_transfer_available = Aohs::MOD_CALL_TRANSFER

  def index

    @usrs = get_my_agent_id_list
    @usrs = nil if @usrs.nil?
    
  end
  
  def get_current_channels_status
    
    ccs_result = nil
    
    if (params.has_key?(:agent_id) and not params[:agent_id].empty?)
      
      agent_id   = params[:agent_id]
      
      ccl = CurrentChannelStatus.select("*, timediff(now(),start_time) as diff").where(["agent_id = ? AND start_time >= ? AND connected = ?",agent_id,Time.now.strftime("%Y-%m-%d 00:00:00"),'connected'])
      ccl = ccl.order("start_time desc").first
      
      unless ccl.nil?
        ccs_result = {}
        ccl.call_id = ccl.id.to_s if ccl.call_id.nil? or ccl.call_id.empty?
        vl  = VoiceLogTemp.where("call_id IN (?) and start_time >= ?",[ccl.id.to_s,ccl.call_id].uniq,Time.now.strftime("%Y-%m-%d 00:00:00"))
        vl  = vl.order("start_time desc").first
        unless vl.nil?
          vlc = VoiceLogCounter.where("voice_log_id = ?",vl.id).first
            
          ccs_result = {
            :call_id => vl.call_id,
            :sys_id => ccl.system_id.to_i,
            :dvc_id => ccl.device_id.to_i,
            :chn_id => ccl.channel_id.to_i,
            :ani => ccl.ani,
            :dnis => ccl.dnis,
            :diff => ccl.diff,
            :c_dir => ccl.call_direction,
            :st_time => ccl.start_time.strftime("%Y-%m-%d %H:%M:%S"),
            :conn => ccl.connected,
            :ng_count => (vlc.nil? ? 0 : vlc.ngword_count),
            :mst_count => (vlc.nil? ? 0 : vlc.mustword_count),
            :voice_url => vl.voice_file_url
          }
        end
      end
  
    end
    
    render :json => ccs_result
    
  end

  def get_info
    
    user_info = []
    statistics_types = {}
    daily_selects = []
    stat_types = []    
    
    statistics_types[:call_count] = StatisticsType.where({:target_model => 'VoiceLog',:value_type => 'count',:by_agent => true}).first.id
    statistics_types[:in_count]   = StatisticsType.where({:target_model => 'VoiceLog',:value_type => 'count:i',:by_agent => true}).first.id
    statistics_types[:out_count]  = StatisticsType.where({:target_model => 'VoiceLog',:value_type => 'count:o',:by_agent => true}).first.id

    if @@keyword_available
      statistics_types[:ng_count]  = StatisticsType.where({:target_model => 'ResultKeyword',:value_type => 'sum:n',:by_agent => true}).first.id
      statistics_types[:mst_count] = StatisticsType.where({:target_model => 'ResultKeyword',:value_type => 'sum:m',:by_agent => true}).first.id
    end
    
    statistics_types.each_pair do |k,v|
      daily_selects << "SUM(IF(statistics_type_id=#{v},value,0)) AS #{k.to_s}"
      stat_types << v
    end
    
    if params.has_key?(:grp_id) and not params[:grp_id].empty?

      grp_id = params[:grp_id]
      leader_id = Group.find(grp_id).leader_id rescue 0

      v = VoiceLogTemp.table_name
      c = CurrentChannelStatus.table_name
      
      usr = []
      usr = User.alive
      usr = usr.select("id, login, display_name, sex, cti_agent_id, group_id")
      if grp_id.to_i >= 0
        usr = usr.where(["(group_id = ? or id = ?) and flag != 1 and state = 'active'", grp_id, leader_id]).order("type desc, display_name").all
      else
        group_managers = GroupManager.where({:user_id => current_user.id })
        group_managers = group_managers.map { |m| m.manager_id }
        group_managers << 0 if group_managers.empty?
        usr = usr.where(["state = 'active' and id in (?)",group_managers]).order("login")
      end
  
      unless usr.empty?
        
        all_agent_id = usr.map{ |u| u.id }
        
        ds = DailyStatistics.select((["agent_id"].concat(daily_selects)).join(","))
        ds = ds.where(["statistics_type_id IN (?) AND start_day = ? AND agent_id IN (?)",stat_types,Time.now.strftime("%Y-%m-%d"),all_agent_id])
        ds = ds.group(:agent_id).all
        
        cs = CurrentChannelStatus.select("*, timediff(now(), start_time) as diff, time(start_time) as st_time")
        cs = cs.where(["agent_id in (?) and connected = 'connected' and start_time >= ?",all_agent_id,Time.now.strftime("%Y-%m-%d 00:00:00")])
        cs = cs.order("start_time desc").all
        
        usr.each do |u|
          
          xu = {}
          xu[:id]    = u.id
          xu[:type]  = (u.id == leader_id ? "Leader" : "Agent")
          xu[:group] = (u.group.nil? ? "-" : u.group.name)
          xu[:name]  = u.display_name
          xu[:sex]   = u.sex
          xu[:ext]   = u.extensions_list.join(", ")
          xu[:cti]   = (u.cti_agent_id.nil? ? "-" : u.cti_agent_id)
          xu[:offline] = "no"
          
          # is offline
          cps = CurrentComputerStatus.where(["login_name LIKE ? and check_time >= ?",u.login.strip,Time.now.strftime("%Y-%m-%d 07:00:00")]).first
          xu[:offline] = "yes" if cps.nil?
          
          # daily statistic
          unless ds.empty?
            ds.each do |d|
              if d.agent_id == u.id
                xu[:total_call] = d.call_count
                xu[:total_in]   = d.in_count
                xu[:total_out]  = d.out_count
                if @@keyword_available
                  xu[:total_ng]  = d.ng_count
                  xu[:total_mst] = d.mst_count
                end
                break
              end
            end
          end
          
          # current status
          unless cs.empty?
            cs.each do |cc|
              if cc.agent_id == u.id
                uvl, uvc = nil, nil
                cc.call_id = cc.id.to_s if cc.call_id.nil? or cc.call_id.empty?
                uvl = VoiceLogTemp.where(["call_id IN (?) AND device_id IS NOT NULL AND system_id IS NOT NULL and channel_id IS NOT NULL",[cc.id.to_s,cc.call_id].uniq]).first
                xu[:call_id] = (uvl.nil? ? cc.call_id : uvl.call_id)
                xu[:call_start_time] = cc.st_time
                xu[:call_ani] = cc.ani
                xu[:call_dnis] = cc.dnis
                xu[:call_duration] = cc.diff
                xu[:call_direction] = cc.call_direction
                xu[:call_conn] = cc.connected
                xu[:call_sys] = cc.system_id.to_i
                xu[:call_dev] = cc.device_id.to_i
                xu[:call_chn] = cc.channel_id.to_i
                if @@keyword_available and not uvl.nil?
                  uvc = VoiceLogCounter.where(["voice_log_id = ?",uvl.id]).first
                  unless uvc.nil?
                    xu[:call_ng] = uvc.ngword_count
                    xu[:call_mst] = uvc.mustword_count
                  end
                end
                break
              end
            end
          end

          user_info << xu
          
        end

      end
    end

    render :json => user_info

  end

  def call_stat

    call_summary = nil
    qry_select = []
    
    s = 7
    e = 19
    (s..e).each_with_index do |t,i|
      case t
      when s then qry_select << "ifnull(sum(case when hour(start_time) < #{s+1} then 1 else 0 end),0) as h#{i}"
      when e then qry_select << "ifnull(sum(case when hour(start_time) >= #{e} then 1 else 0 end),0) as h#{i}"
      else qry_select << "ifnull(sum(case when hour(start_time) >= #{t} and hour(start_time) < #{t+1} then 1 else 0 end),0) as h#{i}"
      end
    end

    if (params.has_key?(:agent_id) and not params[:agent_id].empty?)

      conditions = []
      agent_id = params[:agent_id]

      conditions << "agent_id = #{agent_id}"
      if (params.has_key?(:date) and not params[:date].empty?)
        conditions << "date(start_time) = '#{params[:date]}'"
      else
        conditions << "date(start_time) = date(now())"
      end

      sum = VoiceLogTemp.select(qry_select.join(',')).where(conditions.join(' and ')).first
      unless sum.nil?
        call_summary = {:bfr_egh => sum.h0, :egh => sum.h1, :nine => sum.h2, :ten => sum.h3, :ele => sum.h4, :twlv => sum.h5, :thr => sum.h6,
                        :fort => sum.h7, :fift => sum.h8, :sixt => sum.h9, :sev => sum.h10, :eght => sum.h11, :aft_nint => sum.h12}
      end
      
    end

    render :json => call_summary
  end

  def search_voice_log

    voices = []
    conditions = []

    if (params.has_key?(:agent_id) and not params[:agent_id].empty?)
      
      agent_id = params[:agent_id]
      conditions << "agent_id = #{agent_id}"
      
      if (params.has_key?(:date) and not params[:date].empty?)
        conditions << "date(start_time) = '#{params[:date]}'"
      else
        conditions << "date(start_time) = date(now())"
      end

      if (params.has_key?(:time_from) and not params[:time_from].empty?)
        conditions << "time(start_time) >= '#{params[:time_from]}'"
      end

      if (params.has_key?(:time_to) and not params[:time_to].empty?)
        conditions << "time(start_time) < '#{params[:time_to]}'"
      end

      voice_logs = VoiceLogTemp.select("id, start_time, duration, call_direction, ani, dnis").where(conditions.join(' and ')).order(:start_time).all
      unless voice_logs.empty?
        voice_logs.each do |v|
          current_voice = {}
          current_voice = {
            :id => v.id,
            :start_date => v.start_time.strftime("%Y-%m-%d"),
            :start_time => v.start_time.strftime("%H:%M:%S"),
            :start_hour => v.start_time.strftime("%H"),
            :duration => v.duration,
            :call_direction => v.call_direction,
            :ani => format_phone(v.ani),
            :dnis => format_phone(v.dnis)
          }

          if @@keyword_available
            current_voice[:ng] = v.voice_log_counter.ngword_count
            current_voice[:mst] = v.voice_log_counter.mustword_count
          end

#          if @@call_transfer_available
#            current_voice[:trfc] = v.have_transfered_call?
#          end
          voices << current_voice
        end
      end
    end

    render :json => voices
  end

  def get_destination_agent

    to_agent = nil

    if (params.has_key?(:ext) and not params[:ext].empty?)

      ext = params[:ext]
      u = User.table_name
      e = ExtensionToAgentMap.table_name
      g = Group.table_name

      agent = ExtensionToAgentMap.select("#{e}.agent_id as agent_id, u.login as login_name, u.display_name as name, u.group_id as group_id, u.cti_agent_id as cti, g.name as group_name")
      agent = agent.joins("join #{u} u on #{e}.agent_id = u.id left join #{g} g on g.id = u.group_id").where("#{e}.extension = #{ext}").first
      unless agent.nil?
        to_agent = {:id => agent.agent_id, :login_name => agent.login_name, :name => agent.name, :group_id => agent.group_id, :cti => agent.cti, :group_name => agent.group_name}
      end

    end
    render :json => to_agent
  end

end
