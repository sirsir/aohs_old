--TriggerName=count_statistics_for_result_insert
 
CREATE TRIGGER count_statistics_for_result_insert AFTER INSERT ON result_keywords
FOR EACH ROW BEGIN

	DECLARE xkeyword_type CHAR DEFAULT NULL;
	DECLARE xdate DATE DEFAULT NULL;
	DECLARE xvoice_id INT DEFAULT NULL;
	DECLARE xuser_id INT DEFAULT 0;
	DECLARE xstatistic_type_id1 INT DEFAULT NULL;
	DECLARE xstatistic_type_id2 INT DEFAULT NULL;
	DECLARE xstatistic_id1 INT DEFAULT NULL;	
	DECLARE xstatistic_id2 INT DEFAULT NULL;
	DECLARE xori_id INT DEFAULT NULL;
	DECLARE xori_call_id VARCHAR(255) DEFAULT NULL;

	-- if new result keyword 
	IF new.keyword_id IS NOT NULL AND new.edit_status IS NULL THEN
				
		SELECT keyword_type INTO xkeyword_type FROM keywords WHERE id = new.keyword_id;
		
		IF get_active_logger_id(1) THEN
			SELECT id,CAST(start_time AS DATE),agent_id,ori_call_id INTO xvoice_id,xdate,xuser_id,xori_call_id 
			FROM voice_logs_1 WHERE id = new.voice_log_id LIMIT 1;
			IF xori_call_id != '1' AND xori_call_id IS NOT NULL THEN
				SELECT id INTO xori_id FROM voice_logs_1 WHERE call_id = xori_call_id LIMIT 1;
			END IF;
		ELSE
			SELECT id,CAST(start_time AS DATE),agent_id,ori_call_id INTO xvoice_id,xdate,xuser_id,xori_call_id 
			FROM voice_logs_2 WHERE id = new.voice_log_id LIMIT 1;
			IF xori_call_id != '1' AND xori_call_id IS NOT NULL THEN
				SELECT id INTO xori_id FROM voice_logs_2 WHERE call_id = xori_call_id LIMIT 1;
			END IF;
		END IF;
		
		IF xkeyword_type IS NOT NULL AND xdate IS NOT NULL AND new.voice_log_id IS NOT NULL THEN
		
			-- daily keywords by keyword
			SET xstatistic_type_id1 = find_statistic_type('ResultKeyword','sum',FALSE);
			IF xstatistic_type_id1 IS NOT NULL THEN
				SELECT id INTO xstatistic_id1 FROM daily_statistics 
				WHERE keyword_id = new.keyword_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id1 LIMIT 1;
				IF xstatistic_id1 IS NULL THEN
					INSERT INTO daily_statistics(start_day,keyword_id,statistics_type_id,value,created_at,updated_at) 
					VALUES (xdate,new.keyword_id,xstatistic_type_id1,1,NOW(),NOW());
				ELSE
					UPDATE daily_statistics SET value = value + 1, updated_at = NOW() WHERE id = xstatistic_id1;
				END IF;
			END IF;

			-- daily keywords agent by agent/keyword_type
			SET xstatistic_type_id2 = find_statistic_type('ResultKeyword',CONCAT('sum:',xkeyword_type),TRUE);	
			IF xstatistic_type_id2 IS NOT NULL THEN
				SELECT id INTO xstatistic_id2 FROM daily_statistics 
				WHERE agent_id = xuser_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id2 LIMIT 1;
				IF xstatistic_id2 IS NULL THEN
					INSERT INTO daily_statistics(start_day,agent_id,statistics_type_id,value,created_at,updated_at) 
					VALUES (xdate,xuser_id,xstatistic_type_id2,1,NOW(),NOW());							
				ELSE
					UPDATE daily_statistics SET value = value + 1, updated_at = NOW() WHERE id = xstatistic_id2 LIMIT 1;
				END IF;
			END IF;

			-- voice_logs_counter 
			CASE xkeyword_type 
			WHEN 'n' THEN
				UPDATE voice_log_counters SET keyword_count = keyword_count + 1, ngword_count = ngword_count + 1 WHERE voice_log_id = new.voice_log_id LIMIT 1;
			WHEN 'm' THEN 
				UPDATE voice_log_counters SET keyword_count = keyword_count + 1, mustword_count = mustword_count + 1 WHERE voice_log_id = new.voice_log_id LIMIT 1;
			END CASE;

			-- transfer counter
			IF xori_id IS NOT NULL AND xori_id > 0 THEN
				CASE xkeyword_type
				WHEN 'n' THEN
					UPDATE voice_log_counters SET transfer_ng_count = transfer_ng_count + 1 WHERE voice_log_id = xori_id LIMIT 1;
				WHEN 'm' THEN 
					UPDATE voice_log_counters SET transfer_must_count = transfer_must_count + 1 WHERE voice_log_id = xori_id LIMIT 1;
				END CASE;							
			END IF;

		END IF;

	END IF;

END;