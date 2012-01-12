class CreateTriggerOnBookmarkDel < ActiveRecord::Migration
  def self.up
   # execute "DROP TRIGGER IF EXISTS update_counter_statistic_on_bookmark_del"
    execute <<SQL
    CREATE TRIGGER update_counter_statistic_on_bookmark_del AFTER DELETE ON call_bookmarks
    FOR EACH ROW BEGIN
       DECLARE total_bookmark INT;
        SET total_bookmark = 0;
        IF EXISTS(SELECT id FROM voice_log_counters WHERE voice_log_id = old.voice_log_id) THEN
            SELECT bookmark_count INTO total_bookmark
            FROM voice_log_counters WHERE voice_log_id = old.voice_log_id;
            SET total_bookmark = total_bookmark - 1;
            UPDATE voice_log_counters SET bookmark_count = total_bookmark WHERE voice_log_id = old.voice_log_id;
         END IF;   
    END;
SQL
  end

  def self.down
    execute "DROP TRIGGER IF EXISTS update_counter_statistic_on_bookmark_del"
  end
end
