class CreateScheduleInfos < ActiveRecord::Migration
  def change
    create_table :schedule_infos do |t|
      t.string      :name,      limit: 100
      t.datetime    :last_processed_time
      t.string      :message
      t.string      :status,    limit: 10
      t.timestamps null: false
    end
  end
end
