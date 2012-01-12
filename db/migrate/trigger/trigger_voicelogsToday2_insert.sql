--TriggerName=add_new_counter_on_insert2

CREATE TRIGGER add_new_counter_on_insert2 AFTER INSERT ON voice_logs_today_2
FOR EACH ROW BEGIN
	DECLARE stype INT;
	DECLARE total INT;
	SET total = 0;

	IF (SELECT default_value FROM configurations WHERE variable = 'activeId' LIMIT 1) = '2' THEN
		INSERT INTO voice_log_counters (voice_log_id,keyword_count,ngword_count,mustword_count,bookmark_count,created_at,updated_at) VALUES (new.id,0,0,0,0,NOW(),NOW());
		IF new.agent_id IS NOT NULL AND new.start_time IS NOT NULL THEN
			SELECT id INTO stype FROM statistics_types WHERE target_model = 'VoiceLog' AND value_type = 'count' AND by_agent = 1 LIMIT 1;
			IF EXISTS(SELECT id FROM daily_statistics WHERE start_day = CAST(new.start_time AS DATE) AND agent_id = new.agent_id AND statistics_type_id = stype LIMIT 1) THEN
				SELECT d.value INTO total FROM daily_statistics d WHERE start_day = CAST(new.start_time AS DATE) AND agent_id = new.agent_id AND statistics_type_id = stype LIMIT 1;
				SET total = total + 1;
				UPDATE daily_statistics d SET d.value = total WHERE start_day = CAST(new.start_time AS DATE) AND agent_id = new.agent_id AND statistics_type_id = stype;
			ELSE
				INSERT INTO daily_statistics (start_day,agent_id,statistics_type_id,VALUE,created_at,updated_at) VALUES(CAST(new.start_time AS DATE),new.agent_id,stype,1,NOW(),NOW());
			END IF;
		END IF;
	END IF;
END;