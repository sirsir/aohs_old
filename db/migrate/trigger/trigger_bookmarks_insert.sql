--TriggerName=update_counter_statistic_on_bookmark_insert

CREATE TRIGGER update_counter_statistic_on_bookmark_insert AFTER INSERT ON call_bookmarks
FOR EACH ROW BEGIN
	DECLARE total_bookmark INT;
	SET total_bookmark = 0;
	IF EXISTS(SELECT id FROM voice_log_counters WHERE voice_log_id = new.voice_log_id) THEN
		SELECT bookmark_count INTO total_bookmark FROM voice_log_counters WHERE voice_log_id = new.voice_log_id;
	ELSE
		INSERT INTO voice_log_counters (voice_log_id,created_at,updated_at) VALUES (new.voice_log_id,NOW(),NOW());
	END IF;
	SET total_bookmark = total_bookmark + 1;
	UPDATE voice_log_counters SET bookmark_count = total_bookmark WHERE voice_log_id = new.voice_log_id;
END;