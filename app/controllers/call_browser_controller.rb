class CallBrowserController < ApplicationController

  before_action :authenticate_user!
  
  def index

    p_conf = {
      default_view: Settings.callbrowser.default_view,
      hangup_delay: Settings.callbrowser.hangup_delay_sec,
      callstatus: {
        ws_url: Settings.mq.callstatus.wsurl,
        type:   Settings.mq.callstatus.type,
        dest:   Settings.mq.callstatus.destination
      },
      stream: {
        rootUrl: "http://" + Settings.qlogger.stream_host + ":" + Settings.qlogger.stream_port.to_s + "/" + Settings.qlogger.stream_url.to_s
      },
      duration_colors: Settings.callbrowser.duration_colors.reverse,
      const: {
        userstatus: Settings.callbrowser.user_status.to_h,
        callstatus: Settings.callbrowser.call_status.to_h,
        cdirname: Settings.callbrowser.cdirname.to_h
      }
    }
    
    gon.push({ settings: p_conf })
    
  end
  
  def members
    
    group_id = params[:group_id]
    result = false

    groups = Group.where(id: group_id).all

    unless groups.empty?
      members = GroupMember.leader_and_member.select([:user_id,:member_type]).where(group_id: groups.map { |g| g.id }).all
      leaders = members.map { |m| m.user_id if m.leader? }
      users   = []

      unless members.empty?
        fusers = User.select([:id,:login,:full_name_en,:full_name_th,:role_id,:joined_date]).where(id: members.map { |m| m.user_id }).order(:login).all
        fusers.each do |user|
          
          ccs  = CurrentComputerStatus.select([:remote_ip]).where(login_name: user.login).order(check_time: :desc).first
          uem  = UserExtensionMap.select([:extension]).where(agent_id: user.id).first
          ccnt = VoiceLog.today.where(agent_id: user.id).count(0)
          
          is_logged = (ccs.nil? ? false : true)
          is_logged = (ccnt > 0 ? true : false)
          remot_ip  = (ccs.nil? ? nil : ccs.remote_ip)
          ext_no    = (uem.nil? ? "" : uem.extension)
          if uem.nil? and not ccs.nil?
            cxs = CurrentChannelStatus.select([:extension]).where(agent_id: user.id).first
            unless cxs.nil?
              ext_no = cxs.extension
            end
          end
          
          users << {
            id:             user.id,
            name:           user.display_name,
            group_name:     user.group_name,
            work_years:     StringFormat.days_humanize(user.work_days),
            role_name:      user.role_name,
            current_call:   current_call_status(user.id),
            call_summary:   { tt_inbound: 0, tt_outbound: 0},
            is_active:      is_logged,
            is_leader:      leaders.include?(user.id),
            ext_no:         ext_no
          }
        end
        
        result = {
          total_users:  users.length,
          users:        users
        }
        
      end

    end

    render json: result

  end
  
  def summary_data
    
    user_id = params[:user_id]
    
    result = {
      user_id: user_id,
      call_summary: current_call_summary(user_id)
    }
    
    render json: result
    
  end
  
  def get_voice_log
    
    cond = {
      call_id: params[:call_id],
      system_id: params[:system_id],
      device_id: params[:device_id],
      channel_id: params[:channel_id],
      start_time: params[:start_time],
      ani: params[:ani],
      dnis: params[:dnis],
      call_direction: params[:direction]
    }
    
    vl = VoiceLogToday.where(cond).first
    
    unless vl.nil?
      rs = {
        found: true,
        id: vl.id,
        call_id: vl.call_id      
      }
    else
      rs = {
        found: false
      }
    end
  
    render json: rs 
    
  end

  def call_status
    stime_check = (Time.now - 2.hour).strftime("%Y-%m-%d %H:%M:%S")
    sql = []
    sql << "SELECT c.id, c.site_id, c.system_id, c.device_id, c.channel_id, c.call_direction, c.call_id, c.ani, c.dnis, c.agent_id, c.start_time, c.duration, c.connected"
    sql << "FROM current_channel_status c"
    sql << "WHERE c.start_time >= '#{stime_check}'"
    sql << "AND (c.duration IS NULL OR TIME_TO_SEC(TIMEDIFF(NOW(),ADDDATE(c.start_time,INTERVAL c.duration SECOND))) <= 700)"
    if params.has_key?(:uids) and not params[:uids].empty?
      sql << "AND c.agent_id IN (#{params[:uids].join(",")})"
    end
    sql << "ORDER BY c.start_time"
    result = ActiveRecord::Base.connection.select_all(sql.join(" "))
    result = result.map { |c|
      {
        start_time: c["start_time"].to_formatted_s(:web),
        agent_id: c["agent_id"],
        ani: c["ani"].to_s,
        dnis: c["dnis"].to_s,
        extension: c["extension"].to_s,
        direction: c["call_direction"].to_s,
        duration_sec: c["duration"].to_i,
        call_id: c["call_id"].to_s,
        channel_id: c["channel_id"],
        device_id: c["device_id"],
        system_id: c["system_id"],
        site_ti: c["site_id"],
        call_status: c["connected"].to_s.downcase,
        sts_name: map_status_message(c["connected"])
      }
    }
    render json: result
  end
  
  private
  
  def map_status_message(txt)
    case txt.to_s.downcase
    when "connected"
      return "Talking"
    when "disconnected"
      return "Hangup"
    end
    return ""
  end

  def current_call_status(user_id)
    ccs = CurrentChannelStatus.where(agent_id: user_id).order(start_time: :desc).first
    if not ccs.nil? and ccs.is_connected?
      return {
        start_time:   ccs.start_time.to_formatted_s(:web),
        ani:          ccs.ani,
        dnis:         ccs.dnis,
        extension:    ccs.extension,
        duration_sec: ccs.duration.to_i,
        call_id:      ccs.call_id,
        channel_id:   ccs.channel_id,
        device_id:    ccs.device_id,
        system_id:    ccs.system_id,
        site_id:      ccs.site_id,
        direction:    ccs.call_direction,
        call_status:  ccs.connected,
        sts_name:     ccs.call_status,
        sys_time:     Time.now.to_formatted_s(:web)
      }
    end
    return false
  end

  def current_call_summary(user_id)
    
    inb_count = 0
    inb_duration = 0
    inb_max_duration = 0
    inb_avg_duration = 0
    oub_count = 0
    oub_duration = 0
    oub_max_duration = 0
    oub_avg_duration = 0
    
    selects = [
      "call_direction",
      "COUNT(0) AS call_count",
      "SUM(duration) AS total_duration",
      "MAX(duration) AS max_duration"
    ]
    
    vs = VoiceLog.select(selects.join(",")).today.where(agent_id: user_id).group(:call_direction).all
    vs.each do |v|
      case v.call_direction
      when 'i'
        inb_count = v.call_count.to_i
        inb_duration = v.total_duration.to_i
        inb_max_duration = v.max_duration.to_i
        if inb_count > 0
          inb_avg_duration = inb_duration/inb_count
        end
      when 'o'
        oub_count = v.call_count.to_i
        oub_duration = v.total_duration.to_i
        oub_max_duration = v.max_duration.to_i
        if oub_count > 0
          oub_avg_duration = oub_duration/oub_count
        end
      end
    end
    
    return {
      tt_inbound: inb_count,
      tt_outbound: oub_count,
      mx_duration_inbound: StringFormat.format_sec(inb_max_duration),
      mx_duration_outbound: StringFormat.format_sec(oub_max_duration),
      tt_duration_inbound: StringFormat.format_sec(inb_duration),
      tt_duration_outbound: StringFormat.format_sec(oub_duration),
      avg_duration_inbound: StringFormat.format_sec(inb_avg_duration),
      avg_duration_outbound: StringFormat.format_sec(oub_avg_duration)
    }
    
  end
  
  def group_id
    
    params[:group_id].to_i
    
  end
  
end
