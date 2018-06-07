class CreateUserAtlAttrs < ActiveRecord::Migration
  def change
    create_table :user_atl_attrs do |t|
      t.integer   :user_id,       null: false, foreign_key: false
      t.string    :operator_id,   null: false, default: "", limit: 15, foreign_key: false
      t.string    :team_id,       null: false, default: "", limit: 15, foreign_key: false
      t.string    :performance_group_id, null: false, default: "", limit: 15, foreign_key: false
      t.string    :delinquent_no, null: false, default: "", limit: 10
      t.string    :extension,     null: false, default: "", limit: 20
      t.string    :flag,          null: false, default: "", limit: 3
      t.datetime  :created_at
      t.datetime  :updated_at
    end
    add_index :user_atl_attrs, :user_id
    add_index :user_atl_attrs, :operator_id
  end
end
