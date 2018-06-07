class DashboardController < ApplicationController

  before_action :authenticate_user!
    
  def index
    redirect_to controller: 'home', action: 'index'
  end
  
  def agent_monitor
    conf = {
      settings: {
        auto_update: Settings.dashboard.auto_update,
        interval_update_sec: Settings.dashboard.interval_update_sec,
        delay_load_sec: Settings.dashboard.delay_load_sec
      },
      user: {
        only_own_call: current_user.is_only_own_call?
      }
    }
    gon.push(conf)
  end
  
  
  def qa_manager
    ds = {
      evaluation_count: evaluation_count_by_day,
      evaluation_count_qaagent: evaluation_count_by_qaagent
    }
    render json: ds
  end
  
  def tv_data
    
    # make data element of jstree node
    # - root/all
    # - our groups
    # --- <group>
    # ------ <leader>
    # ------ <member>
    # ------ <sub-group>
    
    data      = []
    root_node = "#"
    data_id   = params[:id]
    
    case data_id  
    when '#'
      
      if current_user.is_only_own_call?
        data << {
          id:       "user-#{current_user.id}",
          parent:   root_node,
          text:     current_user.login,
          icon:     'jsico-user'
        }
      else
        data = [
          { id: "root-all",   parent: root_node, text: "All",       icon: "jsico-group" },
          { id: "group-all",  parent: root_node, text: "Our Group", icon: "jsico-group", children: true }
        ]
      end
      
    when 'group-all'
      
      groups = Group.root.order(:short_name)
      
      no_chk_required = SysPermission.can_do?(current_user.id,"voice_logs","disabled_call_permission")      
      unless no_chk_required
        our_groups = current_user.permiss_groups
        groups = groups.where(id: our_groups)
      end
      
      groups.all.each do |g|
        data << {
          id:       "group-#{g.id}",
          parent:   "group-all",
          text:     g.short_name,
          icon:     'jsico-group',
          children: true
        }
      end
      
    else
      id    = params[:id].gsub("group-","")
      group = Group.where(id: id).first
      unless group.nil?
        parent_node = "group-#{id}"
        
        # add leaader
        users   = group.group_members.only_leader.select(:user_id).order(false)
        leaders = User.select([:id,:login]).not_deleted.where(id: users.map { |u| u.user_id}).order(:login).all
        leaders.each do |u|
          data << {
            id:       "user-#{u.id}",
            parent:   parent_node,
            text:     u.login + "(L)",
            icon:     'jsico-leader'
          }
        end
        
        # add member
        users   = group.group_members.only_member.select(:user_id).order(false)
        members = User.select([:id,:login]).not_deleted.where(id: users.map { |u| u.user_id}).order(:login).all
        members.each do |u|
          data << {
            id:       "user-#{u.id}",
            parent:   parent_node,
            text:     u.login,
            icon:     'jsico-user'
          }
        end
        
        # add child group
        groups = group.childrens.not_deleted.select([:id,:short_name]).all
        groups.each do |g|
          data << {
            id:       "group-#{g.id}",
            parent:   parent_node,
            text:     g.short_name,
            icon:     'jsico-group',
            children: true
          }
        end
      end
    end

    render json: data
    
  end
  
  def das_data
    
    data    = {}
    filter  = {
      qtype: params[:q],
      id:    params[:id],
      date:  params[:d]
    }
    
    filter[:id] = current_user.id if params[:q] == 'groups'
    
    das_cs  = DasbInfo::CallDashboard.new(filter)
    data    = data.merge(das_cs.get_result)
    
    render json: data
 
  end

  def das_timeline
    
    case params[:qt]
    when 'user'
      users   = User.select('id AS user_id').where(id: params[:id]).all
    when 'group'
      group   = Group.not_deleted.where(id: params[:id]).first
      users   = GroupMember.leader_and_member.where(group_id: group.id).all
    end
    
    q_date = Date.today
    if params[:d].present?
      q_date = Date.parse(params[:d])
    end
    
    st_w_hr = Settings.calendar.work_time.first
    ed_w_hr = Settings.calendar.work_time.last
    
    result  = {
      beginning_time: q_date.strftime("%Y-%m-%d #{st_w_hr}"),
      ending_time:    q_date.strftime("%Y-%m-%d #{ed_w_hr}"),           
      users: []
    }
    
    result[:beginning_time_i] = Time.parse(result[:beginning_time]).to_i * 1000;
    result[:ending_time_i]    = Time.parse(result[:ending_time]).to_i * 1000;
    
    selects  = [
      'id',
      'start_time',
      'duration',
      'call_direction',
      "DATE_ADD(start_time, INTERVAL duration second) AS end_time"
    ].join(",")
    
    users.each do |u|
      vls   = VoiceLog.select(selects).start_time_bet(Time.parse(result[:beginning_time]),Time.parse(result[:ending_time])).where(agent_id: u.user_id).order(start_time: :asc).all
      calls = []
      vls.each do |v|
          color = ((v.call_direction == 'o') ? '#1C86EE' : '#00CD00')
          calls << {
            color:          color,
            id:             v.id,
            starting_time:  v.start_time.to_i * 1000, 
            ending_time:    v.end_time.to_i * 1000,
          }
      end
      result[:users] << { user_id: u.user_id, label: 'all', times: calls } 
    end
    
    render json: result  
  
  end

  private
  
  def evaluation_count_by_day
    sdate = (Date.today - 90.days).strftime("%Y-%m-%d")
    edate = Date.today.strftime("%Y-%m-%d")
    data = [[],[]]
    sql = []
    sql << "SELECT d.stats_date, sq.total FROM"
    sql << "dmy_calendars d LEFT JOIN (SELECT date(evaluated_at) AS report_date, COUNT(0) AS total"
    sql << "FROM evaluation_logs l" 
    sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
    sql << "WHERE l.flag <> 'D' AND c.call_date BETWEEN '#{sdate}' AND '#{edate}'"
    sql << "GROUP BY date(evaluated_at)) sq ON sq.report_date = d.stats_date"
    sql << "WHERE d.stats_date BETWEEN '#{sdate}' AND '#{edate}'"
    result = ActiveRecord::Base.connection.select_all(sql.join(" "))
    result.each do |rs|
      data[0] << rs["stats_date"]
      data[1] << rs["total"].to_i
    end
    return data
  end
  
  def evaluation_count_by_qaagent
    sdate = Date.today.strftime("%Y-%m-%d")
    edate = Date.today.strftime("%Y-%m-%d")
    data = []
    sql = []
    sql << "SELECT l.evaluated_by, COUNT(0) AS total FROM evaluation_logs l"
    sql << "JOIN evaluation_calls c ON l.id = c.evaluation_log_id"
    sql << "WHERE l.flag <> 'D' AND c.call_date BETWEEN '#{sdate}' AND '#{edate}'"
    sql << "GROUP BY l.evaluated_by"
    result = ActiveRecord::Base.connection.select_all(sql.join(" "))
    result.each do |rs|
      u = User.where(id: rs["evaluated_by"]).first
      d = {
        display_name: u.display_name,
        group_name: u.group_name,
        total_all: rs["total"]
      }
      data << d
    end
    return data
  end
end
