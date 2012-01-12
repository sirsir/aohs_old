class CreateJobSchedulers < ActiveRecord::Migration
  def self.up
    create_table :job_schedulers do |t|
      t.column  :name,        :string, :limit => 50
      t.column  :parameters,  :string
      t.column  :run_times,   :integer, :limit => 2
      t.column  :run_at,      :datetime 
      t.column  :state,       :string
    end
  end

  def self.down
    drop_table :job_schedulers
  end
end
