class CreateCallEmotions < ActiveRecord::Migration
  def change
    create_table :call_emotions do |t|
      t.integer     :voice_log_id,      null: false, foreign_key: false, limit: 8
      t.integer     :emotion_score,     null: false, default: 0
    end
    add_index :call_emotions, :voice_log_id, name: 'index_voice_id', unique: true
  end
end
