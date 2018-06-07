class AddDeviseFieldsSecu < ActiveRecord::Migration
  def change
    change_table(:users) do |t|
      t.datetime  :password_changed_at
      t.string    :unique_session_id, :limit => 20, foreign_key: false
      t.datetime  :last_activity_at
      t.datetime  :expired_at
    end
    add_index :users, :password_changed_at
  end
end
