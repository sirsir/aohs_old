class EvaluationAssignedTask < ActiveRecord::Base
  
  # assignment state
  # N (New) -> E (Evaluated) 
  #         -> D (Unassign/Deleted)
  #         -> DE (Expried)
  # C (Calibrate)
  #         -> EC (Evaluated)
  #         -> DC (Deleted)
  
  FLAGS_DELETED = ['D','DE','DC']
  FLAGS_ASSIGNED = ['N','E']
  
  scope :only_pending,  ->{
    where(flag: 'N')  
  }
  
  scope :not_deleted, ->{
    where.not(flag: ['D','DE'])
  }
  
  scope :only_closed_or_evaluated, ->{
    where(flag: ['E','EC'])  
  }
  
  scope :by_voice_logs, ->(ids){
    where(voice_log_id: ids)  
  }
  
  scope :by_assignee, ->(ids){
    where(user_id: ids)  
  }
  
  scope :order_by_lastest, ->(){
    order(assigned_at: :desc, id: :desc)  
  }
  
  scope :within_closed_time, ->{
    where(["updated_at >= ?",Time.now.beginning_of_day])  
  }
  
  def self.assigned_to?(voice_log_id, user_id)
    # to check target call. Is it assigned to specific user. 
    task = not_deleted.where(voice_log_id: voice_log_id).first
    unless task.nil?
      return user_id == task.user_id
    end
    # or not assign yet
    return true
  end
  
  def self.get_current_pending_stats
    return select("user_id,COUNT(0) AS pending_count").only_pending.group("user_id").all
  end
  
  def assignee_id
    self.user_id
  end
  
  def content
    unless defined? @contents
      get_contents
    end
    @contents
  end
  
  def reassign_to(new_assignee_id)
    new_assign = self.class.new(self.attributes)
    self.flag = 'D'
    if save
      new_assign.id = nil
      new_assign.flag = 'N'
      new_assign.user_id = new_assignee_id
      new_assign.save
    end
  end
  
  def unassign
    self.flag = 'D'
    save
  end
  
  def evaluated_by(evaluated_by=nil)
    self.flag = 'E'
    unless evaluated_by.nil?
      self.user_id = evaluated_by
    end
  end
  
  private
  
  def get_contents
    @contents = {}
    get_contents_voice_log
    @contents = Hashie::Mash.new(@contents)
  end
  
  def get_contents_voice_log
    v = VoiceLog.where(id: self.voice_log_id.to_i).first
    unless v.nil?
      @contents[:voice_log_id] = v.id
      @contents[:call_datetime] = v.start_time
      @contents[:call_datetime_s] = v.start_time.to_formatted_s(:web)
      @contents[:extension] = v.extension
      @contents[:agent_name] = v.agent_info.display_name
      @contents[:duration] = v.duration
      @contents[:duration_s] = StringFormat.format_sec(v.duration.to_i)
    end
  end
  
end
