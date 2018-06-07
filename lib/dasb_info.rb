module DasbInfo
  
  class CallDashboard
    
    def initialize(filter)
      
      @filter = filter
      
      get_users_list
      get_period
    
    end
    
    def get_result
      
      ds = return_result
      
      ds[:ds][:summary] = find_summary
      
      ds[:chart][:call_by_hrs]    = find_call_by_hour
      ds[:chart][:call_by_rngs]   = find_call_by_duration_range
      
      if defined_groups?
        ds[:table][:group_summary] = find_call_by_group
      end
      
      if defined_users?
        ds[:table][:user_summary] = find_call_by_usr
      end
      
      if qry_for_user?
        ds[:ds][:user] = find_user_info
      end
      
      if qry_for_group?
        ds[:ds][:group] = find_group_info
      end
      
      if qry_for_all?
        ds[:table][:top_dialed_out] = find_repeated_dialed_call
      end
      
      ## Ana Demo
      ds[:table][:ana_demo] = { cclass: [], reason: [], asst: [], csat: [], fcr: [] }
      ds[:table][:ana_demo][:cclass] = {
        list: ["Enquiry","Complain","Service","Suggesstion","Private"],
        result: ["count",100,80,50,10,1]
      }

      ds[:table][:ana_demo][:reason] = {
        list: ["สอบถามโปรโมชั่น","ย้ายค่าย","สอบถามค่าบริการ","แจ้งสัญญาณขัดข้อง","บิลค่าบริการ"],
        result: ["count",100,80,50,10,1]
      }

      ds[:table][:ana_demo][:asst] = {
        list: ["Greeting","Customer Verify","Script Compliance","Call Handling","Follow-up","Closure"],
        result: ["count",100,90,95,80,100,100]
      }

      ds[:table][:ana_demo][:csat] = {
        result: [['satisfied',90],['unsatisfied',10]]
      }

      ds[:table][:ana_demo][:fcr] = {
        result: [['FCR',92],['Non-FCR',7]]
      }
      
      #unless qry_for_groups?
      #  ds[:table][:top_keyword] = find_top_keyword
      #end
      
      # return dataset format -- json
      # chart.<chart_name>
      # table.<table_name>
      # ds.<name> - other
      
      return ds
    
    end
  
    private    
    
    def get_users_list
      
      @users  = false
      @groups = false
      
      @q_type = @filter[:qtype]
      
      case @q_type
      when 'groups'
        
        user_id = @filter[:id]
        user = User.select("id, role_id").where(id: user_id).first

        no_chk_required = SysPermission.can_do?(user.id, "voice_logs", "disabled_call_permission")      
        unless no_chk_required
          our_groups = user.permiss_groups
          @groups = our_groups
        else
          rs = GroupMember.select("DISTINCT group_id").all
          @groups = rs.map { |r| r.group_id }          
        end

      when 'group'
        
        group_id = @filter[:id]
        rs = GroupMember.select(:user_id).leader_and_member.where(group_id: group_id).all
        @users = rs.map { |r| r.user_id }
      
      when 'user'
        
        @users = [@filter[:id]]
      
      end
      
    end
    
    def get_period

      @st_time = Time.now.beginning_of_day      
      @ed_time = Time.now    
      
      if @filter[:date].present?
        d_pam = Date.parse(@filter[:date])
        if d_pam < Date.today
          @st_time = Time.parse(d_pam.to_formatted_s(:db) + " 00:00:00")
          @ed_time = Time.parse(d_pam.to_formatted_s(:db) + " 23:59:59")
        end
      end

    end
    
    def find_user_info
      
      user = User.where(id: @users).first
      unless user.nil?
        return {
          id:           user.id,
          name:         user.display_name,
          role_name:    user.role_name,
          employee_id:  user.employee_id
        }
      end
      
      return false
      
    end

    def find_group_info
      
      group = Group.where(id: @filter[:id]).first
      
      unless group.nil?
        return {
          id:       group.id,
          name:     group.display_name,
          leader_name: group.leader_name.to_s,
          leader_role: nil
        }
      else
        return true
      end
      
    end
    
    def find_repeated_dialed_call
      
      rets     = []
      stats_id = PhonenoStatistic.statistic_type(:count,:outbound_dnis).id
      
      result   = PhonenoStatistic.select("number,SUM(total) AS total")
                                .date_between(@st_time.to_date,@ed_time.to_date)
                                .where(stats_type: stats_id)
                                .exclude_special_no
                                .group("number")
                                .having("SUM(total) >= 2")
                                .order("SUM(total) DESC, number")
                                .limit(5)

      result = select_sql(result.to_sql)
      result.each do |rec|
        rets << {
          number:     StringFormat.format_phone(rec['number']),
          call_count: rec['total'].to_i
        }
      end
      
      return { data: rets }
    
    end
    
    def find_top_keyword
    
      rets = []
      
      return { data: rets }
    
    end
    
    def find_summary
      
      tv  = VoiceLog.table_name
      ret = {}
      
      selects = [
        "COUNT(DISTINCT #{tv}.agent_id) AS tt_agents",
        "MAX(#{tv}.duration) AS max_duration",
        "SUM(#{tv}.duration) AS sum_duration",
        "SUM(IF(#{tv}.call_direction='i',1,0)) AS tt_inb",
        "SUM(IF(#{tv}.call_direction='o',1,0)) AS tt_outb",
        "COUNT(#{tv}.id) AS tt"
      ].join(",")
      
      wheres = {}
    
      if defined_users?
        wheres[:agent_id] = @users
      end
      
      result = VoiceLog.start_time_bet(@st_time, @ed_time)
                       .select(selects)
                       .where(wheres).order(false)
                       .limit(1)
      
      if defined_groups?
        result = result.group_in(@groups)
      end
      
      result = select_sql(result.to_sql).first
      
      return {
        total_users:    result['tt_agents'].to_i,
        avg_duration:   avg_of(result['sum_duration'].to_i,result['tt'].to_i),
        max_duration:   result['max_duration'].to_i,
        total_inbound:  result['tt_inb'].to_i,
        total_outbound: result['tt_outb'].to_i,
        total_call:     result['tt'].to_i
      }
      
    end
    
    def find_call_by_hour
      
      tv  = VoiceLog.table_name
      
      selects = [
        "HOUR(#{tv}.start_time) AS call_hour",
        "SUM(IF(#{tv}.call_direction='i',1,0)) AS tt_inb",
        "SUM(IF(#{tv}.call_direction='o',1,0)) AS tt_outb",
        "SUM(IF(#{tv}.call_direction='i',duration,0)) AS tt_dur_inb",
        "SUM(IF(#{tv}.call_direction='o',duration,0)) AS tt_dur_outb"
      ].join(",")
      
      groups = [
        "HOUR(#{tv}.start_time)"
      ].join(",")
      
      orders = [
        "HOUR(#{tv}.start_time)"
      ].join(",")

      wheres = {}
      
      if defined_users?
        wheres[:agent_id] = @users
      end
      
      result = VoiceLog.start_time_bet(@st_time, @ed_time)
                       .select(selects)
                       .where(wheres)
                       .group(groups).order(orders).limit(24)

      if defined_groups?
        result = result.group_in(@groups)
      end
      
      result = select_sql(result.to_sql)
      
      rets = {
        cols:   ['hour','inbound','outbound'],
        hours:  ['hour'],
        ttinb:  ['inbound'],
        ttoutb: ['outbound'],
        ttinb_dur:  ['inbound'],
        ttoutb_dur: ['outbound']
      }
      
      result.each do |rec|
        rets[:hours]      << rec['call_hour'].to_s
        rets[:ttinb]      << rec['tt_inb'].to_i
        rets[:ttoutb]     << rec['tt_outb'].to_i
        rets[:ttinb_dur]  << avg_of(rec['tt_dur_inb'].to_i, rec['tt_inb'].to_i)
        rets[:ttoutb_dur] << avg_of(rec['tt_dur_outb'].to_i, rec['tt_outb'].to_i)
      end
      
      return rets
    
    end
    
    def find_call_by_duration_range
    
      selects = [
        "voice_logs.call_direction"
      ]
      
      ranges = CallStatistic.statistic_type_ranges(:count, :all, :duration_range)
      unless ranges.empty?
        ranges.each do |r|
          if not r.lower_bound.nil? and not r.upper_bound.nil?
            selects << "SUM(IF(voice_logs.duration BETWEEN #{r.lower_bound} AND #{r.upper_bound},1,0)) AS #{r.label}"
          else
            selects << "SUM(IF(voice_logs.duration >= #{r.lower_bound},1,0)) AS #{r.label}"
          end
        end
      end

      wheres = {}
      if defined_users?
        wheres[:agent_id] = @users
      end

      groups = [
        "call_direction"
      ].join(",")
      
      result = VoiceLog.start_time_bet(@st_time, @ed_time).select(selects).where(wheres).group(groups).all
      
      rets = {
        cols:   ['range','inbound','outbound'],
        ranges:  ['range'],
        inb:    ['inbound'],
        outb:   ['outbound']
      }
      
      ranges.each do |r|
        rets[:ranges] << r.display_name
      end
      
      unless result.empty?
        result.each do |rs|  
          case rs.call_direction
          when 'i'
            ranges.each {|r| rets[:inb] << rs.attributes[r.label]}  
          when 'o'
            ranges.each {|r| rets[:outb] << rs.attributes[r.label]}
          end
        end
      end
      
      return rets
    
    end
    
    def find_call_by_group
      
      xgroups = Group.where(id: @groups).order(:pathname).all

      rets = []
      
      xgroups.each do |g|
        rec = {
          id: g.id,
          name: g.display_name,
          leader_name: g.leader_name
        }
        
        selects = [
          "group_members.user_id",
          "voice_logs.call_direction",
          "MAX(voice_logs.duration) AS max_duration",
          "SUM(voice_logs.duration) AS sum_duration",
          "COUNT(voice_logs.id) as total_count"
        ].join(",")
      
        groups = [
          "group_members.user_id",        
          "voice_logs.call_direction"
        ].join(",")
      
        wheres = ["group_members.member_type IN ('L','M') AND group_members.group_id = ?", g.id]
      
        sql_a = VoiceLog.start_time_bet(@st_time, @ed_time).select(selects)
                        .where(wheres)
                        .joins("LEFT JOIN group_members ON voice_logs.agent_id = group_members.user_id")
                        .group(groups).to_sql
      
        selects = [
          "COUNT(DISTINCT user_id) as tt_agents",
          "call_direction",
          "MAX(max_duration) AS max_duration2",
          "AVG(sum_duration/total_count) AS avg_duration2",
          "SUM(total_count) AS tt_call",
          "AVG(total_count) AS avg_call"
        ]
      
        sql_b = "SELECT #{selects.join(",")} FROM (#{sql_a}) x GROUP BY call_direction"
      
        result = select_sql(sql_b)
        result.each do |rs|
          case rs['call_direction']
          when 'i'
            rec = rec.merge({
              inb_total:  rs['tt_call'],
              inb_maxd:   StringFormat.format_sec(rs['max_duration2']),
              inb_avgd:   StringFormat.format_sec(rs['avg_duration2']),
              inb_avgc:   rs['avg_call'].to_i
            })
          when 'o'
            rec = rec.merge({
              oub_total:  rs['tt_call'],
              oub_maxd:   StringFormat.format_sec(rs['max_duration2']),
              oub_avgd:   StringFormat.format_sec(rs['avg_duration2']),
              oub_avgc:   rs['avg_call'].to_i
            })
          end
        end
        rets << rec
      end
    
      return rets
    
    end
    
    def find_call_by_usr
      
      users = User.not_deleted.where(id: @users).order(:login).all
      
      selects = [
        "voice_logs.agent_id",
        "voice_logs.call_direction",
        "MAX(voice_logs.duration) AS max_duration",
        "AVG(voice_logs.duration) AS avg_duration",
        "COUNT(voice_logs.id) as total_call"
      ].join(",")
      
      groups = [
        "voice_logs.agent_id",        
        "voice_logs.call_direction"
      ].join(",")
      
      wheres = ["voice_logs.agent_id IN (?)",@users]
      
      result = VoiceLog.start_time_bet(@st_time, @ed_time).select(selects).group(groups).where(wheres).all

      rets = []
      unless users.empty?
        users.each do |u|
          x = {
            id:   u.id,
            name: u.display_name
          }
          result.each do |rs|
            next if rs.agent_id != u.id
            case rs.call_direction
            when 'i'
              x = x.merge({
                inb_total:  rs.total_call,
                inb_maxd:   StringFormat.format_sec(rs.max_duration),
                inb_avgd_sec: rs.avg_duration,
                inb_avgd:   StringFormat.format_sec(rs.avg_duration)
              })
            when 'o'
              x = x.merge({
                oub_total:  rs.total_call,
                oub_maxd:   StringFormat.format_sec(rs.max_duration),
                oub_avgd_sec: rs.avg_duration,
                oub_avgd:   StringFormat.format_sec(rs.avg_duration)
              })
            end
            
          end
          # ToDo Demo
          begin
          x = x.merge({
            fcr: (x[:inb_total] + x[:oub_total]) - (rand(x[:oub_total])),
            aht: StringFormat.format_sec((x[:inb_avgd_sec] + x[:oub_avgd_sec])/2 + rand(30)),
            csat: [0.6,0.7,0.75,0.8,0.85,0.9,0.95,1.0].sample * 100,
            asst: [0.6,0.7,0.75,0.8,0.85,0.9,0.95,1.0].sample * 100
          })
          if x[:asst] <= 70
            x[:asst_badge] = "badge badge-warning"
          end
          if x[:asst] <= 70
            x[:emo_id] = 2
          else
            x[:emo_id] = 4
          end
          rescue =>e
            STDOUT.puts e.message
          end
          rets << x
        end
      end
      
      return rets
    
    end
    
    def defined_groups?
      
      return @groups != false
    
    end
    
    def defined_users?
      
      return @users != false
    
    end
    
    def qry_for?(q)
      
      return @q_type.to_s == @filter[:qtype].to_s.downcase
    
    end
    
    def qry_for_user?
      
      return qry_for?(:user)
    
    end
    
    def qry_for_group?
      
      return qry_for?(:group)
    
    end
    
    def qry_for_groups?
      
      return qry_for?(:groups)
    
    end
    
    def qry_for_all?
      
      return qry_for?(:all)
    
    end
    
    def return_result
      
      return {
        chart: {},
        table: {},
        ds:    {}
      }
    
    end
    
    def select_sql(sql)
    
      return ActiveRecord::Base.connection.select_all(sql)  
  
    end
  
    def avg_of(a,b)
      
      return a/b rescue 0
    
    end
    
    def pct_of(a,b)
      
        
    end
    
  end
  
end