class CreateTableInfos < ActiveRecord::Migration
  def change
    create_table :table_infos, id: false do |t|
      t.string      :db_name,       limit: 100
      t.string      :tbl_name,      limit: 100
      t.string      :engine_name,   limit: 50
      t.integer     :rows_count
      t.integer     :data_length
      t.integer     :index_length
      t.integer     :data_free
      t.datetime    :updated_at
    end
    add_index :table_infos, [:db_name, :tbl_name], name: 'index_dbtbl', unique: true
  end
end
