class CreateSystemConsts < ActiveRecord::Migration
  def change
    create_table :system_consts do |t|
      t.string    :cate,          null: false, limit: 15
      t.string    :code,          null: false, limit: 15
      t.string    :name,          null: false, limit: 50
      t.string    :flag,          null: false, limit: 1, default: ""
      t.string    :as_default,    null: false, limit: 1, default: ""
    end
    add_index :system_consts, :cate
    add_index :system_consts, [:cate, :code],   unique: true
  end
end
