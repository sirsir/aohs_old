--TriggerName=update_counter_statistic_on_bookmark_del
 
CREATE TRIGGER update_counter_statistic_on_bookmark_del AFTER DELETE ON call_bookmarks
FOR EACH ROW BEGIN
	DECLARE counter_id INT DEFAULT NULL;
	SELECT id INTO counter_id FROM voice_log_counters WHERE voice_log_id = old.voice_log_id;
	IF counter_id IS NOT NULL THEN
		UPDATE voice_log_counters SET bookmark_count = bookmark_count - 1 WHERE voice_log_id = old.voice_log_id LIMIT 1;
	END IF;
END;