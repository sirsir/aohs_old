class CreateProgramInfos < ActiveRecord::Migration
  def change
    create_table :program_infos do |t|
      t.string      :name,      limit: 100
      t.string      :bg_color,  limit: 10
      t.string      :fg_color,  limit: 10
    end
  end
end
