class ChangeSchedTbl < ActiveRecord::Migration
  def self.up
    
    remove_column :job_schedulers,  :run_times 
    remove_column :job_schedulers,  :run_at
    remove_column :job_schedulers,  :state
    
    add_column :job_schedulers,  :desc,       :string
    add_column :job_schedulers,  :updated_at, :datetime
    add_column :job_schedulers,  :state,      :string,  :limit => 20
    
  end

  def self.down
  end
end
