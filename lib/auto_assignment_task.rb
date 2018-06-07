class AutoAssignmentTask
  
  def self.run
    aat = new
    aat.start_assign
  end
  
  def initialize
    do_init
  end
  
  def start_assign
    if @task_count > 0
      @tasks.each do |task|
        if task.schedule_active?
          log :info, "Create assignment for #{task.name}"
          log :info, "Options: #{task.task_options.inspect}"
          task.create_assignment
        end
      end
    end
  end
  
  private
  
  def do_init
    @tasks = EvaluationTask.only_active.all
    @task_count = @tasks.count(0)
  end
  
  def log(type, msg)
    STDOUT.puts msg  
  end
  
end
