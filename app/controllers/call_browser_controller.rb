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
      
      agent_id = params[:agent_id]
      v        = VoiceLogTemp.table_name
      c        = CurrentChannelStatus.table_name

      #cs_select = "#{c}.id as call_id, #{c}.system_id, #{c}.voice_file_url,#{c}.device_id, #{c}.channel_id, #{c}.ani, #{c}.dnis, #{c}.call_direction, #{c}.start_time, #{c}.connected, timediff(now(), #{c}.start_time) as diff"
      cs_select = "#{c}.call_id as call_id, #{c}.system_id, #{c}.device_id, #{c}.channel_id, #{c}.ani, #{c}.dnis, #{c}.call_direction, #{c}.start_time, #{c}.connected, timediff(now(), #{c}.start_time) as diff"
      cs_join = ""
      if @@keyword_available
        vc = VoiceLogCounter.table_name
        cs_select += ", vc.mustword_count as mst, vc.ngword_count as ng"
        #cs_join = "join #{v} v on v.call_id = #{c}.id and date(v.start_time) = date(now()) join #{vc} vc on vc.voice_log_id = v.id and date(vc.created_at) = date(now())"
        cs_join = "join #{v} v on v.call_id = #{c}.call_id and date(v.start_time) = date(now()) join #{vc} vc on vc.voice_log_id = v.id and date(vc.created_at) = date(now())"
      end

      cs = CurrentChannelStatus.select(cs_select)
      cs = cs.joins(cs_join)
      cs = cs.where("#{c}.agent_id = #{agent_id} and date(#{c}.start_time) = date(now()) and #{c}.connected = 'connected'").order("#{c}.start_time desc").first
      
      unless cs.nil?
        ng = 0
        mst = 0
        if @@keyword_available
          ng = cs.ng.nil? ? 0 : cs.ng
          mst = cs.mst.nil? ? 0 : cs.mst
        end

        ccs_result = {
          :call_id => cs.call_id,
          :sys_id => cs.system_id,
          :dvc_id => cs.device_id,
          :chn_id => cs.channel_id,
          :ani => cs.ani,
          :dnis => cs.dnis,
          :diff => cs.diff,
          :c_dir => cs.call_direction,
          :st_time => cs.start_time.strftime("%Y-%m-%d %H:%M:%S"),
          :conn => cs.connected,
          :ng_count => ng,
          :mst_count => mst,
          :voice_url => cs.voice_file_url
        }
      end
    end

    render :json => ccs_result
    
  end

  def get_info
    user_info = [];
    statistics_types = {};
    statistics_types[:call_count] = StatisticsType.where({:target_model => 'VoiceLog',:value_type => 'count',:by_agent => true}).first.id
    statistics_types[:in_count] = StatisticsType.where({:target_model => 'VoiceLog',:value_type => 'count:i',:by_agent => true}).first.id
    statistics_types[:out_count] = StatisticsType.where({:target_model => 'VoiceLog',:value_type => 'count:o',:by_agent => true}).first.id

    if @@keyword_available
      statistics_types[:ng_count] = StatisticsType.where({:target_model => 'ResultKeyword',:value_type => 'sum:n',:by_agent => true}).first.id
      statistics_types[:mst_count] = StatisticsType.where({:target_model => 'ResultKeyword',:value_type => 'sum:m',:by_agent => true}).first.id
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
      c = CurrentChannelStatus.table_name

      usr = User.alive.select("id, display_name, sex, cti_agent_id, group_id").where(["(group_id = ? or id = ?) and flag != 1 and state = 'active'", grp_id, leader_id]).order("type desc, display_name").all
      unless usr.empty?
        all_agent_id = usr.map{ |u| u.id}.join(', ')

        ds = DailyStatistics.select("agent_id, #{daily_selects.join(",")}")
        ds = ds.where("statistics_type_id in (#{stat_types.join(",")}) and start_day = date(now()) and agent_id in (#{all_agent_id})").group(:agent_id).all
        
        cs_select = "#{c}.agent_id, #{c}.id ,#{c}.call_id, #{c}.ani, #{c}.dnis, #{c}.call_direction, #{c}.connected,
                     timediff(now(), #{c}.start_time) as diff, time(#{c}.start_time) as st_time,
                     #{c}.system_id, #{c}.device_id, #{c}.channel_id"
        join_counter = ""

        if @@keyword_available
          vc = VoiceLogCounter.table_name
          cs_select += ", vc.mustword_count as mst, vc.ngword_count as ng"
          #join_counter = "join #{v} v on v.call_id = #{c}.id and date(v.start_time) = date(now()) join #{vc} vc on vc.voice_log_id = v.id and date(vc.created_at) = date(now())"
          join_counter = "join #{v} v on v.call_id = #{c}.call_id and date(v.start_time) = date(now()) join #{vc} vc on vc.voice_log_id = v.id and date(vc.created_at) = date(now())"
        end
        
        cs = CurrentChannelStatus.select(cs_select)
        cs = cs.joins(join_counter)
        cs = cs.where("date(#{c}.start_time) = date(now()) and #{c}.agent_id in (#{all_agent_id}) and #{c}.connected = 'connected'").order("#{c}.start_time desc").all

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

          # daily statistic
          unless ds.empty?
            ds.each do |d|
              if d.agent_id == u_id
                current_user[:total_call] = d.call_count
                current_user[:total_in] = d.in_count
                current_user[:total_out] = d.out_count
                if @@keyword_available
                  current_user[:total_ng] = d.ng_count
                  current_user[:total_mst] = d.mst_count
                end
                break
              end
            end
          end
          # current status
          unless cs.empty?
            cs.each do |cc|
              if cc.agent_id == u_id
                current_user[:call_id] = cc.id
                #current_user[:call_id] = cc.call_id
                current_user[:call_start_time] = cc.st_time
                current_user[:call_ani] = cc.ani
                current_user[:call_dnis] = cc.dnis
                current_user[:call_duration] = cc.diff
                current_user[:call_direction] = cc.call_direction
                current_user[:call_conn] = cc.connected
                current_user[:call_sys] = cc.system_id
                current_user[:call_dev] = cc.device_id
                current_user[:call_chn] = cc.channel_id
                if @@keyword_available
                  current_user[:call_ng] = cc.ng
                  current_user[:call_mst] = cc.mst
                end
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
