class CreatePhonenoStatistics < ActiveRecord::Migration
  def change
    create_table :phoneno_statistics do |t|
      t.integer     :stats_date_id,     null: false, foreign_key: false
      t.string      :number,            limit: 25
      t.string      :formatted_number,  limit: 25
      t.string      :phone_type,        limit: 3, null: false, default: ""
      t.string      :stats_type,        null: false
      t.integer     :total,             default: 0
      t.datetime    :updated_at
    end
    add_index :phoneno_statistics, :stats_date_id, name: 'index_date1'
  end
end
