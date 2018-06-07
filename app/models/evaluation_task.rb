class EvaluationTask < ActiveRecord::Base
  
  FLAG_SCHEDULE = "S"
  FLAG_SCHEDULE_DISABLED = "DS"
  MAX_TASK_INQUEUE = 5
  
  has_paper_trail

  has_many      :evaluation_task_attrs
  has_many      :evaluation_plans, through: :evaluation_task_attrs
  
  strip_attributes  allow_empty: true,
                    collapse_spaces: true

  validates   :title,
                presence: true,
                length: {
                  minimum: 2,
                  maximum: 50
                }

  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)
  }
  
  scope :only_active, ->{
    where.not(flag: [DB_DELETED_FLAG, FLAG_SCHEDULE_DISABLED])  
  }
  
  def self.get_assigenment_cases
    # To get list of assignment profile
    case_list = []
    case_list << { name: 'inbound', label: 'Inbound Call', call_direction: 'i' }
    case_list << { name: 'outbound', label: 'Outbound Call', call_direction: 'o' }
    #case_list << { name: 'cigna_sale', label: 'Sale Policy', call_direction: 'o', group_by: 'policy_no' }
    #case_list << { name: 'cigna_cms', label: 'Customer Service' }
    return case_list
  end

  # add or update any parameters and options
  # to process the assignment tasks
  # this data will be stored in table evaluation-task-atts
  
  def add_options(opts={})
    @options = {} unless defined? @options
    @options = @options.merge(opts)
    if @options["task_type"].present?
      task_type(@options["task_type"])
    end
  end

  def task_options
    unless defined? @options
      load_options
    end
    @options
  end
  
  # find new assignments follow input paramerters and options
  # return summary or list of assignments
  
  def get_new_assignment_info(is_summary=true)
    data = {
      by_date: {
        data: [], summary: []
      },
      record_count: 0,
      total_duration: 0,
      max_voice_log_id: 0,
      list: []
    }
    
    # create query follow parameters
    conds = []

    # by assignment case
    case @options["case_name"]
    when "inbound"
      @options["filter_cd"] = 'i'
    when "outbound"
      @options["filter_cd"] = 'o'  
    end
    
    # by call daterange
    unless @options["filter_daterange"].blank?
      date = @options["filter_daterange"].split(" - ")
      conds << "v.start_time BETWEEN '#{date.first}' AND '#{date.last}'"
    else
      date = Date.today.strftime("%Y-%m-%d")
      conds << "v.start_time >= '#{date} 00:00:00'"
    end
    
    # by extension
    unless @options["filter_extension"].blank?
      exts = @options["filter_extension"].split(/\s|,/).map { |x| "'#{x.strip}'" }
      conds << "v.extension IN (#{exts.join(",")})"
    end
    
    # by ani
    unless @options["filter_ani"].blank?
      nums = @options["filter_ani"].split(/\s|,/).map { |x| "'#{x.strip}'" }
      conds << "v.ani IN (#{nums.join(",")})"
    end
    
    # by dnis
    unless @options["filter_dnis"].blank?
      nums = @options["filter_dnis"].split(/\s|,/).map { |x| "'#{x.strip}'" }
      conds << "v.dnis IN (#{nums.join(",")})"
    end
    
    # by direction
    unless @options["filter_cd"].blank?
      conds << "v.call_direction LIKE '#{@options["filter_cd"]}'"  
    end
    
    # by agent-id
    unless @options["filter_agent_id"].blank?
      conds << "v.agent_id = '#{@options["filter_agent_id"]}'"
    end
    
    # by group-id
    unless @options["filter_group_id"].blank?
      g = Group.where(id: @options["filter_group_id"]).first
      u = [-1]
      unless g.nil?
        u = u.concat(g.list_members_id)
      end
      conds << "v.agent_id IN (#{u.join(",")})"
    end
    
    # by duration range
    unless @options["filter_duration_from"].blank?
      fr_sec = @options["filter_duration_from"].to_i * 60
      conds << "v.duration >= #{fr_sec}"  
    else
      conds << "v.duration > 0"  
    end
    unless @options["filter_duration_to"].blank?
      to_sec = @options["filter_duration_to"].to_i * 60
      conds << "v.duration <= #{to_sec}"  
    end

    # limit number of record to select
    limit_duration = -1
    limit_record = -1
    if not is_summary and not @options["assign_select"].blank?
      case @options["assign_select"]
      when "limit_record"
        limit_record = @options["assign_limit_records"].to_i
      when "limit_duration"
        # hr to seconds
        limit_duration = @options["assign_limit_duration"].to_f * (60 * 60)
      end
    end
    
    # exclude assigned tasks
    dflags = (EvaluationAssignedTask::FLAGS_DELETED.map { |f| "'#{f}'" }).join(",")
    sql_exist = []
    sql_exist << "SELECT 1 FROM evaluation_assigned_tasks e"
    sql_exist << "WHERE e.flag NOT IN (#{dflags}) AND v.id = e.voice_log_id"
    conds << "NOT EXISTS (#{sql_exist.join(" ")})"
    
    # build sql query
    sql = []
    select = []
    group = []
    order = []
    
    if is_summary
      select << "date(v.start_time) AS call_date"
      select << "SUM(v.duration) AS total_duration"
      select << "COUNT(0) AS total_record"
      group  << "date(v.start_time)"
    else
      select << "v.id AS voice_log_id"
      select << "v.duration AS tt_duration"
      select << "1 AS record_count"
      order  << "v.start_time DESC, v.id DESC" 
    end
    
    sql << "SELECT " << select.join(",")
    sql << "FROM voice_logs v"
    sql << "WHERE " << conds.join(" AND ")
    unless group.empty?
      sql << "GROUP BY " << group.join(",")
    end
    unless order.empty?
      sql << "ORDER BY " << order.join(",")
    end
    
    sql = sql.join(" ")
    result = ActiveRecord::Base.connection.select_all(sql)
    
    if is_summary
      unless result.empty?
        result.each do |r|
          data[:by_date][:data] << {
            call_date: r["call_date"],
            record_count: r["total_record"].to_i,
            total_duration_text: StringFormat.secs_humanize(r["total_duration"]),
            avg_duration: StringFormat.secs_humanize(r["total_duration"]/r["total_record"])
          }
          data[:record_count] += r["total_record"].to_i
          data[:total_duration] += r["total_duration"].to_i
        end
        data[:total_duration_text] = StringFormat.secs_humanize(data[:total_duration])
        data[:by_date][:summary] << {
          record_count: data[:record_count],
          total_duration_text: StringFormat.secs_humanize(data[:total_duration]),
          avg_duration: StringFormat.secs_humanize(data[:total_duration]/data[:record_count])
        }
      end
    else
      result.each do |r|
        data[:list] << {
          voice_log_id: r["voice_log_id"].to_i,
          total_duration: r["tt_duration"].to_i,
          record_count: r["record_count"]
        }
        data[:record_count] += 1
        data[:total_duration] += r["duration"].to_i
        break if limit_record > 0 and data[:record_count] >= limit_record
        break if limit_duration > 0 and data[:total_duration] >= limit_duration
      end
    end
    
    Rails.logger.info "Assignment Info: #{data.to_json}, limit-record=#{limit_record}, limit-duration=#{limit_duration}"
    
    return data
  end
  
  # to get current assignment status of each assignees
  # number of assigned tasks, number of pending tasks
  
  def get_current_task_status    
    sql = []
    sql << "SELECT user_id, flag, COUNT(0) AS record_count, SUM(total_duration) AS total_duration"
    sql << "FROM evaluation_assigned_tasks"
    sql << "WHERE flag IN ('N','E')"
    sql << "AND assigned_at >= '#{Time.now.strftime("%Y-%m-%d")} 00:00:00'"
    sql << "AND evaluation_task_id = '#{self.id}'"
    sql << "GROUP BY user_id, flag"
    
    sql = sql.join(" ")
    result = ActiveRecord::Base.connection.select_all(sql)
    
    data = {}
    result.each do |r|
      u_id = r["user_id"].to_s
      if data[u_id].nil?
        data[u_id] = {
          assigned_count: 0,
          assigned_duration: 0,
          pending_evaluate: 0
        }
      end
      case r["flag"]
      when "N"
        data[u_id][:assigned_count] += r["record_count"].to_i
        data[u_id][:assigned_duration] += r["total_duration"].to_i
      when "E"
        data[u_id][:assigned_count] += r["record_count"].to_i
        data[u_id][:assigned_duration] += r["total_duration"].to_i
        data[u_id][:pending_evaluate] += r["record_count"].to_i
      end
    end

    return data
  end
  
  # to check and prepare assignments to assignee as parameters
  # some data may changed cause re-check before assign
  
  def get_new_assigned_users
    
    max_record = -1
    max_duration = -1
    
    data = get_new_assignment_info(false)
    voice_logs = data[:list]
    
    user_count = @options["assign_users"].length
    user_count_assign = get_current_task_status
    assigned = @options["assign_users"].map { |u|
      ({ user_id: u, total_duration: 0, record_count: 0, list: [] }).merge(user_count_assign[u.to_s] || {})
    }
    
    # assign method
    assign_method = @options["assign_method"]
    case @options["assign_perperson"]
    when "avg_record"
      max_record = (data[:record_count].to_f/user_count.to_f).ceil
    when "custom_record"
      max_record = @options["assign_custom_records"].to_i
    when "avg_duration"
      max_duration = (data[:total_duration].to_f/user_count.to_f).ceil 
    when "custom_duration"
      # hr to seconds
      max_duration = @options["assign_custom_duration"] * (60 * 60)
    when "agent_available"
      max_record = MAX_TASK_INQUEUE
      assigned.each do |u|
        u[:pending_count] = u[:pending_evaluate].to_i
      end
    end
    
    # set current assignment status
    unless assigned.empty?
      assigned.each do |u|
        u[:record_count] = u[:assigned_count].to_i
        u[:total_duration] = u[:assigned_duration].to_i
      end
      assigned = assigned.sort_by { |u| [u[:record_count],u[:total_duration]] }
    end
    
    Rails.logger.info "Assignment Info: max-record=#{max_record}, max-duration=#{max_duration} for each person."
    
    case assign_method
    when "sequential"
      assigned.each do |u|
        while ((u[:record_count] < max_record and max_record > 0) or (u[:total_duration] < max_duration and max_duration > 0)) and (not voice_logs.empty?)
          if u[:pending_count].nil? or u[:pending_count] <= MAX_TASK_INQUEUE
            v = voice_logs.shift
            u[:list] << {
              voice_log_id: v[:voice_log_id],
              total_duration: v[:total_duration],
              record_count: v[:record_count]
            }
            u[:record_count] += 1
            u[:total_duration] += v[:total_duration]
          else
            break
          end
        end
      end
    when "distribution"
      while not voice_logs.empty?
        assigned.each do |u|
          if ((u[:record_count] < max_record and max_record > 0) or (u[:total_duration] < max_duration and max_duration > 0)) and (not voice_logs.empty?)
            if u[:pending_count].nil? or u[:pending_count] <= MAX_TASK_INQUEUE
              v = voice_logs.shift
              u[:list] << {
                voice_log_id: v[:voice_log_id],
                total_duration: v[:total_duration],
                record_count: v[:record_count]
              }
              u[:record_count] += 1
              u[:total_duration] += v[:total_duration]
            else
              break
            end
          end
        end
      end
    end
    
    return { assigned_users: assigned }
  end
  
  # to create or update task
  # run-once: create -> assign -> delete
  # run-schedule: create/update -> assign -> finish -> delete
  
  def create_or_update_task
    self.title = check_task_name(@options["task_title"])
    self.description = @options["task_description"]
    self.start_date = @options["task_start_date"]
    self.end_date = @options["task_end_date"]
    if save!
      update_task_attrs
    end
    return {
      task: {
        id: self.id
      }
    }
  end
  
  # create assignements to table evaluation-assigned-tasks
    
  def create_assignment
    data = get_new_assigned_users
    exp_date = get_task_expiry_date
    
    assigned_users = data[:assigned_users]
    assigned_users.each do |u|
      at = {
        user_id: u[:user_id],
        evaluation_task_id: self.id,
        assigned_by: @options["assigned_by"],
        assigned_at: Time.now.to_formatted_s(:db)
      }
      u[:list].each do |vd|
        new_at = EvaluationAssignedTask.new(at)
        new_at.voice_log_id = vd[:voice_log_id]
        new_at.record_count = vd[:record_count]
        new_at.total_duration = vd[:total_duration]
        new_at.expiry_at = exp_date
        new_at.flag = "N"
        new_at.save!
      end
    end
  end
  
  def check_assigned_summary
    data = {
      by_qa: []
    }
    
    cond = []
    cond << "a.flag = 'N'"
    
    # case
    case @options["assigned_case"]
    when "inbound"
      cond << "v.call_direction = 'i'"
    when "outbound"
      cond << "v.call_direction = 'o'"
    end
    
    # assigned_daterange
    unless @options["assigned_daterange"].blank?
      d = dsplit(@options["assigned_daterange"])
      cond << "a.assigned_at BETWEEN '#{d[:st]}' AND '#{d[:ed]}'"
    else
      d = 90.days.ago.strftime("%Y-%m-%d 00:00:00")
      cond << "a.assigned_at >= '#{d}'"
    end
    
    # content_daterange
    unless @options["content_daterange"].blank?
      d = dsplit(@options["content_daterange"])
      cond << "v.start_time BETWEEN '#{d[:st]}' AND '#{d[:ed]}'"
    end
    
    sql = []
    sql << "SELECT a.user_id, COUNT(0) AS record_count"
    sql << "FROM evaluation_assigned_tasks a"
    sql << "JOIN voice_logs v ON a.voice_log_id = v.id"
    sql << "WHERE #{cond.join(" AND ")}"
    sql << "GROUP BY a.user_id"
    
    sql = sql.join(" ")
    result = ActiveRecord::Base.connection.select_all(sql)
    
    result.each do |r|
      u = User.where(id: r["user_id"]).first
      data[:by_qa] << {
        qa_id: r["user_id"],
        qa_name: u.display_name,
        assigned_count: r["record_count"]
      }
    end
    
    return data
  end
  
  def unassign_tasks
    ret = []
    unless @options["unassign"].blank?
      @options["unassign"] = @options["unassign"].to_a.map { |x| x[1] }
      @options["unassign"].each do |asg|
        tasks = EvaluationAssignedTask.by_assignee(asg["assignee_id"]).only_pending
        tasks = tasks.limit(asg["nofunassign"]).order_by_lastest.all
        asg[:unassigned_count] = tasks.count(0)
        tasks.each do |t|
          t.unassign
        end
        ret << asg
      end
    end
    return ret
  end
  
  def name
    self.title
  end
  
  def task_type(type=nil)
    if type.nil?
      case self.flag
      when "O"
        return "run_once"
      when "S"
        return "schedule"
      end
    else
      case type
      when "run_once"
        self.flag = "O"
      when "schedule"
        self.flag = "S"
      end
      return type
    end
    return "run_once"
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
  end
  
  def schedule_task?
    return (task_type == "schedule")
  end
  
  def schedule_active?
    unless self.start_date.blank?
      if self.start_date < Date.today
        # wait to start
        return false
      end
    end
    unless self.end_date.blank?
      if self.end_date > Date.today
        # expired
        return false
      end
    end
    return schedule_enabled?  
  end
  
  def do_disable
    self.flag = FLAG_SCHEDULE_DISABLED
  end
  
  def do_enable
    self.flag = FLAG_SCHEDULE
  end
  
  def schedule_disabled?
    self.flag == FLAG_SCHEDULE_DISABLED
  end

  def schedule_enabled?
    self.flag == FLAG_SCHEDULE
  end
    
  private

  def update_task_attrs
    EvaluationTaskAttr.where(evaluation_task_id: self.id).delete_all
    @options.each_pair do |key, val|
      next if val.to_s.length <= 0
      ta = {
        evaluation_task_id: self.id,
        attr_type: key,
        attr_val: val.to_s
      }
      ta = EvaluationTaskAttr.new(ta)
      ta.save
    end
  end
  
  def load_options
    @options = {}
    attrs = EvaluationTaskAttr.where(evaluation_task_id: self.id).all
    attrs.each do |attr|
      aval = attr.attr_val.to_s
      case attr.attr_type
      when "assign_users"
        aval = JSON.parse(aval)
      end
      @options[attr.attr_type] = aval
    end
  end

  def dsplit(dstr)
    d = dstr.split(" - ")
    return { st: d.first, ed: d.last }
  end

  def check_task_name(t)
    # if task name not defined, system will generate it by default
    if t.blank?
      return "TaskAssignment-#{Time.now.strftime("%Y%m%d%H%M")}"
    end
    return t
  end

  def get_task_expiry_date
    exp_date = nil
    unless @options["task_expiry_in"].blank?
      exp_days = @options["task_expiry_in"].to_i
      if exp_days > 0
        exp_date = Time.now + exp_days.days
      end
    end
    unless @options["task_end_date"].blank?
      exp_date = Time.parse(@options["task_end_date"]).end_of_day
    end
    return exp_date
  end
  
  # end class
end
