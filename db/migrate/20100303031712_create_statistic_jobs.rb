class CreateStatisticJobs < ActiveRecord::Migration
  def self.up
    create_table :statistic_jobs do |t|
      t.column      :start_date,  :date
      t.column      :keyword_id,  :integer
      t.column      :act, :string             # delete | change_type
    end
  end

  def self.down
    drop_table :statistic_jobs
  end
end
