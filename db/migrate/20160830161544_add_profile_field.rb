class AddProfileField < ActiveRecord::Migration
  def change
    add_column  :users, :dsr_profile_id, :string,  limit: 25, foreign_key: false
    add_column  :users, :notes, :string,  limit: 120
  end
end
