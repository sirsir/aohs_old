module EvaluationAssignment
  
  class AssignTask
    
    def initialize(opts={})
      @opts = opts
      Rails.logger.info "Assignment Parameter: #{@opts.inspect}"
    end
    
    def check
      find_select_data
      evaluators
    end
    
    def simulate
      assign_task
    end
    
    def proceed
      unless @assigned_users.empty?
        @assigned_users.each do |u|
          u[:list].each do |v_id|
            t = WfTask.create_call_task(v_id)
            t.assign_to(u[:id])
          end
        end
      end
    end
    
    def result
      return {
        select_data: @select_data,
        evaluators: @evaluators,
        assigned_summary: @assigned_summary
      }
    end
    
    private
    
    def evaluators
      # list all of avaliable evaluators or assignee
      @evaluators = []
      users = User.evaluator.not_deleted.all
      users.each do |u|
        @evaluators << {
          id: u.id,
          display_name: u.display_name,
          selected: false,
          pending_count: 0,
          pending_duration: 0
        }
      end
      find_assigned_data
    end
    
    def find_assigned_data
      # find assigned list and count by date
      p = @opts[:select_data]
      # query
      sql = []
      sql << "SELECT v.id AS voice_log_id, DATE(v.start_time) AS call_date, v.duration FROM voice_logs v"
      sql << "WHERE v.start_time BETWEEN '#{p[:date_fr]}' AND '#{p[:date_to]}'"
      sql1 = sql.join(" ")
      sql = []
      sql << "SELECT wt.assignee_id, COUNT(0) AS total_record, SUM(v.duration) AS total_duration"
      sql << "FROM wf_tasks wt JOIN (#{sql1}) v ON wt.voice_log_id = v.voice_log_id"
      sql << "WHERE wt.last_state_id IN (1)"
      sql << "GROUP BY wt.assignee_id"
      sql = sql.join(" ")
      # result
      result = SqlClient.select(sql)
      result.each do |r|
        i = @evaluators.index { |x| x[:id] == r["assignee_id"].to_i }
        if i >= 0
          @evaluators[i][:pending_count] = r["total_record"].to_i
          @evaluators[i][:pending_duration] = duration_min(r["total_duration"].to_i)
        end
      end
    end
    
    def find_select_data
      # find unassigned detail
      p = @opts[:select_data]
      # query
      sql = []
      sql << "SELECT v.id AS voice_log_id, DATE(v.start_time) AS call_date, v.duration FROM voice_logs v"
      sql << "WHERE v.start_time BETWEEN '#{p[:date_fr]}' AND '#{p[:date_to]}'"
      sql1 = sql.join(" ")
      sql = []
      sql << "SELECT v.call_date, COUNT(0) AS total_record, SUM(v.duration) AS total_duration,"
      sql << "SUM(IF(wt.last_state_id = 1,1,0)) AS assigned_count, SUM(IF(wt.last_state_id = 1,duration,0)) AS assigned_duration"
      sql << "FROM (#{sql1}) v LEFT JOIN wf_tasks wt ON wt.voice_log_id = v.voice_log_id"
      sql << "GROUP BY DATE(v.call_date)"
      sql = sql.join(" ")
      # result
      result = SqlClient.select(sql)
      
      found = {
        select_list: [],
        all_count: 0,
        all_duration: 0,
        assigned_count: 0,
        assigned_duration: 0,
        remain_count: 0,
        remain_duration: 0
      }
      
      result.each do |rs|
        found[:select_list] << {
          call_date: rs["call_date"],
          all_count: rs["total_record"].to_i,
          all_duration: duration_min(rs["total_duration"].to_i),
          assigned_count: rs["assigned_count"].to_i,
          assigned_duration: duration_min(rs["assigned_duration"].to_i),
          remain_count: rs["total_record"].to_i - rs["assigned_count"].to_i,
          remain_duration: duration_min(rs["total_duration"].to_i) - duration_min(rs["assigned_count"].to_i)
        }
      end
      
      # summary date
      found[:select_list].each do |ele|
        ele.each do |k,v|
          if found.has_key?(k)
            found[k] += v
          end
        end
      end
      
      @select_data = found
    end
    
    def assign_parameters
      p = @opts[:assign_data]
      case p[:select_by]
      when "record"
        p[:max_select_record] = p[:select_limit]
        @select_data = @select_data.take(p[:max_select_record])
        p[:max_select_duration] = 0
        @select_data.each { |x| p[:max_select_duration] += x["duration"].to_i}
        p[:max_select_duration] = p[:max_select_duration]
      when "duration"
        p[:select_limit] = p[:select_limit] * 60
        p[:max_select_duration] = duration_sec(p[:select_limit])
        new_data = []
        dx = 0
        @select_data.each do |x|
          new_data << x
          dx += x["duration"].to_i
          break if dx >= p[:max_select_duration] 
        end
        @select_data = new_data
      end
      @assigned_users = p[:assignee].map { |u|
        { id: u.to_i, count: 0, duration: 0, list: [] }
      }
      
      p[:max_record_per_person] = -1
      p[:max_duration_per_person] = -1
      if @assigned_users.length > 0
        case p[:assign_by]
        when "avg_record"
          p[:max_record_per_person] = (p[:max_select_record]/@assigned_users.length).to_i
        when "custom_record"
          p[:max_record_per_person] = p[:assign_limit]
        when "avg_duration"
          p[:max_duration_per_person] = (p[:max_select_duration]/@assigned_users.length).to_i
        when "custom_duration"
          p[:max_duration_per_person] = duration_sec(p[:assign_limit]*60)
        end
      end
      @opts[:assign_data] = p
      return p
    end
    
    def assign_task
      p = @opts[:select_data]
      # query
      sql = []
      sql << "SELECT v.id AS voice_log_id, DATE(v.start_time) AS call_date, v.duration FROM voice_logs v"
      sql << "WHERE v.start_time BETWEEN '#{p[:date_fr]}' AND '#{p[:date_to]}'"
      sql1 = sql.join(" ")
      sql = []
      sql << "SELECT v.voice_log_id, v.duration"
      sql << "FROM (#{sql1}) v LEFT JOIN wf_tasks wt ON v.voice_log_id = wt.voice_log_id"
      sql << "WHERE wt.id IS NULL"
      sql << "ORDER BY v.voice_log_id"
      sql = sql.join(" ")
      # result
      result = SqlClient.select(sql).to_a
      @select_data = result
      
      # params
      q = assign_parameters
      
      # try to assign
      case q[:assign_mode]
      when "sequential"
        @assigned_users.each do |u|
          while (not result.empty?) and (not job_full?(u[:count],u[:duration]))
            v = result.shift
            unless v.nil?
              u[:count] += 1
              u[:duration] += v["duration"].to_i
              u[:list] << v["voice_log_id"].to_i
            end
          end
        end
      when "distribute"
        i = 0
        while not result.empty?
          v = result.shift
          u = @assigned_users[i]
          while (not v.nil?)
            if (not u.nil?) and (not job_full?(u[:count],u[:duration]))
              u[:count] += 1
              u[:duration] += v["duration"].to_i
              u[:list] << v["voice_log_id"].to_i
              v = nil
            end
            i += 1
            i = 0 if i >= @assigned_users.length
          end
        end
      end
      
      # update evaluator
      @assigned_summary = {
        assignee_count: @assigned_users.length,
        assigned_count: 0,
        assigned_duration: 0,
        assigned_avg_count: 0,
        assigned_avg_duration: 0
      }
      @assigned_users.each do |u|
        i = @evaluators.index { |x| x[:id] == u[:id] }
        if i >= 0
          @evaluators[i][:selected] = true
          @evaluators[i][:assign_count] = u[:count]
          @evaluators[i][:assign_duration] = duration_min(u[:duration])
          @evaluators[i][:total_count] = u[:count] + @evaluators[i][:pending_count]
          @evaluators[i][:total_duration] = duration_min(u[:duration] + @evaluators[i][:pending_duration])
          @assigned_summary[:assigned_count] += u[:count]
          @assigned_summary[:assigned_duration] += duration_min(u[:duration])
        end
      end
      if @assigned_summary[:assigned_count] > 0
        @assigned_summary[:assigned_avg_count] = @assigned_summary[:assigned_count]/@assigned_users.length
        @assigned_summary[:assigned_avg_duration] = @assigned_summary[:assigned_duration]/@assigned_users.length
      end
      
    end
    
    def job_full?(t_record,t_duration)
      c = @opts[:assign_data]
      if c[:max_record_per_person] > -1
        return (t_record >= c[:max_record_per_person])
      elsif c[:max_duration_per_person] > -1
        return (t_duration >= c[:max_duration_per_person])
      end
      return true
    end
    
    def duration_min(secs)
      return (secs/60).to_i
    end
    
    def duration_sec(min)
      return (min*60).to_i
    end
    
    # end class
  end
  
  class UnassignTask

    def initialize(opts={})
      @opts = opts
      Rails.logger.info "Un-Assignment Parameter: #{@opts.inspect}"
    end
    
    def check
      find_assigned_data
    end
    
    def proceed
      find_assigned_data
      re_assign
    end
    
    def result
      return {
        assignees: @assignees
      }  
    end
    
    private

    def find_assigned_data
      @assignees = []
      p = @opts[:select_data]
      # query
      sql = []
      sql << "SELECT v.id AS voice_log_id, DATE(v.start_time) AS call_date, v.duration FROM voice_logs v"
      sql << "WHERE v.start_time BETWEEN '#{p[:date_fr]}' AND '#{p[:date_to]}'"
      sql1 = sql.join(" ")
      sql = []
      sql << "SELECT wt.assignee_id, COUNT(0) AS total_record, SUM(v.duration) AS total_duration"
      sql << "FROM (#{sql1}) v JOIN wf_tasks wt ON v.voice_log_id = wt.voice_log_id"
      sql << "WHERE wt.last_state_id IN (1)"
      sql << "GROUP BY wt.assignee_id"
      # result
      result = SqlClient.select(sql.join(" "))
      result.each do |r|
        u = User.where(id: r["assignee_id"]).first
        @assignees << {
          id: u.id,
          display_name: u.display_name,
          assigned_count: r["total_record"].to_i,
          assigned_duration: duration_min(r["total_duration"].to_i)
        }
      end
    end
    
    def find_assigned_list(assignee_id)
      p = @opts[:select_data]
      # query
      sql = []
      sql << "SELECT v.id AS voice_log_id, DATE(v.start_time) AS call_date, v.duration FROM voice_logs v"
      sql << "WHERE v.start_time BETWEEN '#{p[:date_fr]}' AND '#{p[:date_to]}'"
      sql1 = sql.join(" ")
      sql = []
      sql << "SELECT wt.id AS task_id, v.voice_log_id, v.duration"
      sql << "FROM (#{sql1}) v JOIN wf_tasks wt ON v.voice_log_id = wt.voice_log_id"
      sql << "WHERE wt.last_state_id IN (1) AND wt.assignee_id = #{assignee_id}"
      result = SqlClient.select(sql.join(" ")).to_a
      return result
    end
    
    def re_assign
      p = @opts[:reassign_data]
      p[:assignees].each do |u|
        i = @assignees.index { |x| x[:id] == u[:assignee_id].to_i }
        if not i.nil? and i >= 0
          @assignees[i][:list] = find_assigned_list(u[:assignee_id])
          @assignees[i][:unassign_count] = u[:unassign_count].to_i
          @assignees[i][:unassign_list] = @assignees[i][:list].take(u[:unassign_count].to_i)
          @assignees[i][:unassign_duration] = 0
        end
      end
      @assignees.each_with_index do |u,i|
        if @assignees[i][:unassign_count].to_i > 0
          @assignees[i][:unassign_list].each do |a|
            t = WfTask.find_id(a["task_id"]).first
            t.unassign
            @assignees[i][:unassign_duration] += a["duration"].to_i
          end
          @assignees[i][:assigned_count] = @assignees[i][:assigned_count] - @assignees[i][:unassign_count]
          @assignees[i][:unassign_duration] = duration_min(@assignees[i][:unassign_duration])
          @assignees[i][:assigned_duration] = @assignees[i][:assigned_duration] - @assignees[i][:unassign_duration]
        end
      end
    end
    
    def duration_min(secs)
      return (secs/60).to_i
    end
    
    # end class  
  end
  
  # end module
end