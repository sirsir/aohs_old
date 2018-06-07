class CreateEmotionInfos < ActiveRecord::Migration
  def change
    create_table :emotion_infos do |t|  
      t.string     :title,          null: false, limit: 100
      t.string     :image_name,     null: false, limit: 100
    end
  end
end
