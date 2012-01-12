class CallBrowserController < ApplicationController

  before_filter :login_required, :except => [:get_info, :get_current_channels_status, :get_prvious_call, :call_stat, :search_voice_log]
  #before_filter :permission_required

  include AmiCallSearch
  
  layout 'call_browser'

  @@keyword_available = Aohs::MOD_KEYWORDS
  @@call_transfer_available = Aohs::MOD_CALL_TRANSFER

  def index
    
  end

  def get_previous_call

    prev_call_id = [];
    if(params.has_key?(:agent_id) and not params[:agent_id].empty?)
      agent_id = params[:agent_id]
      pv = VoiceLogTemp.find(:all, :select => :id, :conditions => "agent_id = #{agent_id} and date(start_time) = date(now())", :order => "id desc", :limit => 2)
      unless pv.nil?
        pv.each do |p|
          prev_call_id << {:id => p.id}
        end
      end
    end

    render :json => prev_call_id
  end
  
  def get_current_channels_status
    
    ccs_result = nil
    if (params.has_key?(:agent_id) and not params[:agent_id].empty?)
      agent_id = params[:agent_id]
      c = CurrentChannelStatus.find(:first, :select => "id as call_id, system_id, device_id, channel_id, ani, dnis, call_direction, start_time, connected, timediff(now(), start_time) as diff, voice_file_url",
                                    :conditions => "agent_id = #{agent_id} and date(start_time) = '#{Time.now.strftime("%Y-%m-%d")}'",
                                    :order => "start_time desc")
      unless c.nil?
        ng = 0
        mst = 0
        vid = VoiceLogTemp.find(:first, :conditions => {:call_id => c.call_id}).id
        unless vid.nil?
          vc_counter = VoiceLogCounter.find(:first, :conditions => {:voice_log_id => vid})
          if not vc_counter.nil?
            ng = vc_counter.ngword_count.nil? ? 0 : vc_counter.ngword_count
            mst = vc_counter.mustword_count.nil? ? 0 : vc_counter.mustword_count
          end
        end

        ccs_result = {:call_id => c.call_id, :sys_id => c.system_id, :dvc_id => c.device_id, :chn_id => c.channel_id, :ani => c.ani, :dnis => c.dnis, :diff => c.diff,
          :c_dir => c.call_direction, :st_time => c.start_time.strftime("%Y-%m-%d %H:%M:%S"), :conn => c.connected, :ng_count => ng, :mst_count => mst, :voice_url => c.voice_file_url}
      end
    end

    render :json => ccs_result
    
  end

  def get_info
    
    user_info = [];
    statistics_types = {};

    if @@keyword_available
      statistics_types[:ng_count] = StatisticsType.find(:first, :conditions => {:target_model => 'ResultKeyword',:value_type => 'sum:n',:by_agent => true}).id
      statistics_types[:mst_count] = StatisticsType.find(:first, :conditions => {:target_model => 'ResultKeyword',:value_type => 'sum:m',:by_agent => true}).id
    end

    daily_selects = []
    stat_types = []
    statistics_types.each_pair do |k,v|
      daily_selects << "sum(case statistics_type_id when #{v} then value else 0 end) as #{k.to_s}"
      stat_types << v
    end
    
    if (params.has_key?(:grp_id) and not params[:grp_id].empty?)

      grp_id = params[:grp_id]
      leader_id = Group.find(grp_id).leader_id

      v = VoiceLogTemp.table_name
      vc = VoiceLogCounter.table_name
      c = CurrentChannelStatus.table_name

      usr = User.find(:all, :select => "id, display_name, sex, cti_agent_id, group_id", :conditions => ["(group_id = ? or id = ?) and flag != 1", grp_id, leader_id])
      unless usr.empty?
        agent_id = usr.map{ |u| u.id}.join(', ')
        vt = VoiceLogTemp.find(:all, :select => "agent_id, count(id) as call_count,
                                 sum(case call_direction when 'o' then 1 else 0 end) as out_count,
                                 sum(case call_direction when 'i' then 1 else 0 end) as in_count",
                               :conditions => "date(start_time) = date(now()) and agent_id in (#{agent_id})", :group => :agent_id)

        cs = CurrentChannelStatus.find(:all,
                                       :select => "#{c}.agent_id, #{c}.id, #{c}.ani, #{c}.dnis, #{c}.call_direction, #{c}.connected, #{c}.voice_file_url,
                                                   timediff(now(), #{c}.start_time) as diff, time(#{c}.start_time) as st_time,
                                                   #{c}.system_id, #{c}.device_id, #{c}.channel_id, vc.mustword_count as mst, vc.ngword_count as ng",
                                       :joins => "join #{v} v on v.call_id = #{c}.id and date(v.start_time) = date(now())
                                                  join #{vc} vc on vc.voice_log_id = v.id and date(vc.created_at) = date(now())",
                                       :conditions => "date(#{c}.start_time) = date(now()) and #{c}.agent_id in (#{agent_id}) and #{c}.connected = 'connected'",
                                       :order => "#{c}.start_time desc")

        ds = DailyStatistics.find(:all, :select => "agent_id, #{daily_selects.join(",")}",
                                  :conditions => "statistics_type_id in (#{stat_types.join(",")}) and start_day = date(now()) and agent_id in (#{agent_id})",
                                  :group => :agent_id)

        usr.each do |u|
          current_user = {}
          u_id = u.id
          type = (u.id == leader_id ? "Leader" : "Agent")

          current_user[:id] = u_id
          current_user[:type] = type
          current_user[:group] = (u.group.nil? ? "-" : u.group.name)
          current_user[:name] = u.display_name
          current_user[:sex] = u.sex
          current_user[:ext] = u.extensions_list.join(", ")
          current_user[:cti] = (u.cti_agent_id.nil? ? "-" : u.cti_agent_id)

          # total call
          unless vt.empty?
            vt.each do |vtt|
              if vtt.agent_id == u_id
                current_user[:total_call] = vtt.call_count
                current_user[:total_in] = vtt.in_count
                current_user[:total_out] = vtt.out_count
                break
              end
            end
          end
          # daily statistic
          unless ds.empty?
            ds.each do |d|
              if d.agent_id == u_id
                current_user[:total_ng] = d.ng_count
                current_user[:total_mst] = d.mst_count
                break
              end
            end
          end
          # current status
          unless cs.empty?
            cs.each do |cc|
              if cc.agent_id == u_id
                current_user[:call_id] = cc.id
                current_user[:call_start_time] = cc.st_time
                current_user[:call_ani] = cc.ani
                current_user[:call_dnis] = cc.dnis
                current_user[:call_duration] = cc.diff
                current_user[:call_direction] = cc.call_direction
                current_user[:call_conn] = cc.connected
                current_user[:call_sys] = cc.system_id
                current_user[:call_dev] = cc.device_id
                current_user[:call_chn] = cc.channel_id
                current_user[:call_ng] = cc.ng
                current_user[:call_mst] = cc.mst
                current_user[:call_voice_url] = cc.voice_file_url
                break
              end
            end
          end

          user_info << current_user
          
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

      sum = VoiceLogTemp.find(:first, :select => qry_select.join(','), :conditions => conditions.join(' and '))
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

      voice_logs = VoiceLogTemp.find(:all,:select => "id, start_time, duration, call_direction, ani, dnis", :conditions => conditions.join(' and '), :order => :start_time)
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
            :ani => v.ani,
            :dnis => v.dnis
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

end
