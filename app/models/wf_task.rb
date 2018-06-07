class WfTask < ActiveRecord::Base
  
  has_many  :wf_task_transitions
  
  scope :find_id, ->(id){
    where(id: id)  
  }
  
  scope :only_assigned, ->{
    where(last_state_id: 1)  
  }

  scope :only_evaluated, ->{
    where(last_state_id: 3)  
  }
  
  def self.create_call_task(voice_log_id)
    wtask = {
      voice_log_id: voice_log_id
    }
    return new(wtask)
  end
  
  def assign_to(assignee_id)
    if self.id.nil?
      save
    end
    self.assignee_id = assignee_id
    self.last_state_id = 1
    
    t_log = self.wf_task_transitions.new
    t_log.prev_state_id = 0
    t_log.wf_task_state_id = 1
    t_log.assignee_id = assignee_id

    t_log.save
    save
  end
  
  def unassign
    self.last_state_id = 2
    self.flag = 'D'
    
    t_log = self.wf_task_transitions.new
    t_log.wf_task_state_id = 2
    
    t_log.save
    save
  end
  
  def evaluated
    self.last_state_id = 3
    
    t_log = self.wf_task_transitions.new
    t_log.wf_task_state_id = 3
    
    t_log.save
    save
  end
  
  def details
    @details = {}
    if self.voice_log_id.to_i > 0
      c = VoiceLog.where(id: self.voice_log_id).first
      @details[:call_time] = c.start_time.to_formatted_s(:web)
      @details[:call_duration] = StringFormat.format_sec(c.duration)
    end
    if self.evaluation_log_id.to_i > 0
      l = EvaluationLog.where(id: self.evaluation_log_id).first
      @details[:evaluated_date] = l.evaluated_at.to_formatted_s(:web) 
    end
    return @details
  end
  
end
