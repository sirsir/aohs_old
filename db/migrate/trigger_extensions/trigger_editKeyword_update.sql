--TriggerName=count_statistics_when_edit_change
 
CREATE TRIGGER count_statistics_when_edit_change AFTER UPDATE ON edit_keywords
FOR EACH ROW BEGIN
		
	DECLARE okeyword_type CHAR DEFAULT NULL;
	DECLARE nkeyword_type CHAR DEFAULT NULL;

	DECLARE xkeyword_type CHAR DEFAULT NULL;
	DECLARE xdate DATE DEFAULT NULL;
	DECLARE xvoice_id INT DEFAULT NULL;
	DECLARE xuser_id INT DEFAULT 0;
	DECLARE xstatistic_type_id1 INT DEFAULT NULL;
	DECLARE xstatistic_type_id2 INT DEFAULT NULL;
	DECLARE xstatistic_type_id3 INT DEFAULT NULL;
	DECLARE xori_id INT DEFAULT NULL;
	DECLARE xori_call_id VARCHAR(255) DEFAULT NULL;
	
	SELECT keyword_type INTO xkeyword_type FROM keywords WHERE id = new.keyword_id;	
	
	IF get_active_logger_id(1) THEN
		SELECT id,CAST(start_time AS DATE),agent_id,ori_call_id INTO xvoice_id,xdate,xuser_id,xori_call_id FROM voice_logs_1 WHERE id = new.voice_log_id LIMIT 1;
		IF xori_call_id != '1' AND xori_call_id IS NOT NULL THEN
			SELECT id INTO xori_id FROM voice_logs_1 WHERE call_id = xori_call_id LIMIT 1;
		END IF;
	ELSE
		SELECT id,CAST(start_time AS DATE),agent_id,ori_call_id INTO xvoice_id,xdate,xuser_id,xori_call_id FROM voice_logs_2 WHERE id = new.voice_log_id LIMIT 1;
		IF xori_call_id != '1' AND xori_call_id IS NOT NULL THEN
			SELECT id INTO xori_id FROM voice_logs_2 WHERE call_id = xori_call_id LIMIT 1;
		END IF;
	END IF;
	
	IF xkeyword_type IS NOT NULL AND xdate IS NOT NULL AND xvoice_id IS NOT NULL THEN
		
		-- delete result keywords
		IF new.edit_status = 'd' AND (old.edit_status != new.edit_status) THEN

			-- daily keywords by keyword
			SET xstatistic_type_id1 = find_statistic_type('ResultKeyword','sum',FALSE);	
			IF xstatistic_type_id1 IS NOT NULL THEN
				UPDATE daily_statistics SET value = value - 1 
				WHERE keyword_id = new.keyword_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id1 LIMIT 1;
			END IF;

			-- daily keywords agent by agent/keyword_type
			SET xstatistic_type_id2 = find_statistic_type('ResultKeyword',CONCAT('sum:',xkeyword_type),TRUE);	
			IF xstatistic_type_id2 IS NOT NULL THEN
				UPDATE daily_statistics d SET d.value = value - 1 
				WHERE agent_id = xuser_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id2 LIMIT 1;
			END IF;

			-- voice_logs_counter 
			CASE xkeyword_type
			WHEN 'n' THEN
				UPDATE voice_log_counters SET keyword_count = keyword_count - 1,ngword_count = ngword_count - 1 WHERE voice_log_id = new.voice_log_id LIMIT 1;
			WHEN 'm' THEN
				UPDATE voice_log_counters SET keyword_count = keyword_count - 1,mustword_count = mustword_count - 1 WHERE voice_log_id = new.voice_log_id LIMIT 1;
			END CASE;

			-- transfer counter
			IF xori_id IS NOT NULL AND xori_id > 0 THEN
				CASE xkeyword_type
				WHEN 'n' THEN 
					UPDATE voice_log_counters SET transfer_ng_count = transfer_ng_count - 1 WHERE voice_log_id = xori_id LIMIT 1;
				WHEN 'm' THEN 
					UPDATE voice_log_counters SET transfer_must_count = transfer_must_count - 1 WHERE voice_log_id = xori_id LIMIT 1;
				END CASE;									
			END IF;
		
		ELSEIF new.edit_status = 'e' THEN			
		
			-- if keyword changed 
			IF old.keyword_id != new.keyword_id THEN	

				-- daily keywords by keyword
				SET xstatistic_type_id1 = find_statistic_type('ResultKeyword','sum',FALSE);
				IF xstatistic_type_id1 IS NOT NULL THEN
					-- increase new
					UPDATE daily_statistics SET value = value + 1 
					WHERE keyword_id = new.keyword_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id1 LIMIT 1;
					-- decrease old
					UPDATE daily_statistics SET value = value - 1 
					WHERE keyword_id = old.keyword_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id1 LIMIT 1;
				END IF;
				
				SELECT keyword_type INTO okeyword_type FROM keywords WHERE id = old.keyword_id; 
				SELECT keyword_type INTO nkeyword_type FROM keywords WHERE id = new.keyword_id; 	
					
				-- keyword type changed 
				IF okeyword_type != nkeyword_type THEN
				
					-- daily keywords agent by agent/keyword_type
					-- decrease
					SET xstatistic_type_id2 = find_statistic_type('ResultKeyword',CONCAT('sum:',okeyword_type),TRUE);	
					IF xstatistic_type_id2 IS NOT NULL THEN
						UPDATE daily_statistics d SET d.value = value - 1 
						WHERE agent_id = xuser_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id2 LIMIT 1;
					END IF;
					-- increase
					SET xstatistic_type_id3 = find_statistic_type('ResultKeyword',CONCAT('sum:',nkeyword_type),TRUE);	
					IF xstatistic_type_id3 IS NOT NULL THEN 
						UPDATE daily_statistics d SET d.value = value + 1 
						WHERE agent_id = xuser_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id3 LIMIT 1;
					END IF;

					-- voice_logs_counter 
					CASE nkeyword_type
					WHEN 'n' THEN
						UPDATE voice_log_counters SET ngword_count = ngword_count + 1,mustword_count = mustword_count - 1 WHERE voice_log_id = new.voice_log_id LIMIT 1;
					WHEN 'm' THEN 
						UPDATE voice_log_counters SET ngword_count = ngword_count - 1,mustword_count = mustword_count + 1 WHERE voice_log_id = new.voice_log_id LIMIT 1;
					END CASE;

					-- transfer counter
					IF xori_id IS NOT NULL AND xori_id > 0 THEN
						CASE nkeyword_type
						WHEN 'n' THEN
							UPDATE voice_log_counters SET transfer_ng_count = transfer_ng_count + 1,transfer_must_count = transfer_must_count - 1 WHERE voice_log_id = xori_id LIMIT 1;
						WHEN 'm' THEN 
							UPDATE voice_log_counters SET transfer_ng_count = transfer_ng_count - 1,transfer_must_count = transfer_must_count + 1 WHERE voice_log_id = xori_id LIMIT 1;
						END CASE;									
					END IF;
				
				END IF;
				
			END IF;

		END IF;
		
	END IF;	
END;