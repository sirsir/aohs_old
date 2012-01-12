--TriggerName=add_voicelogs_1_statistics_afins
 
CREATE TRIGGER add_voicelogs_1_statistics_afins AFTER INSERT ON voice_logs_today_1
FOR EACH ROW BEGIN

	DECLARE xstatistic_type_id1 INT DEFAULT NULL;
	DECLARE xstatistic_type_id2 INT DEFAULT NULL;
	DECLARE daily_id1 INT DEFAULT NULL;
	DECLARE daily_id2 INT DEFAULT NULL;	
	DECLARE cd VARCHAR(1);
	
	IF get_active_logger_id(1) THEN

		INSERT INTO voice_log_counters(voice_log_id,keyword_count,ngword_count,mustword_count,bookmark_count,transfer_call_count,transfer_in_count,transfer_out_count,transfer_ng_count,transfer_must_count,created_at,updated_at) 
		VALUES (new.id,0,0,0,0,0,0,0,0,0,NOW(),NOW());

		CASE new.call_direction
		WHEN 'i' THEN 
			SET cd = 'i';
			-- CALL mapping_customer(new.id,new.ani);
		WHEN 'o' THEN 
			SET cd = 'o';
			-- CALL mapping_customer(new.id,new.dnis);
		ELSE 
			SET cd = 'e';
		END CASE;
		
		IF new.agent_id IS NOT NULL AND new.start_time IS NOT NULL THEN

			SET xstatistic_type_id1 = find_statistic_type('VoiceLog','count',TRUE);

			SELECT id INTO daily_id1 FROM daily_statistics 
			WHERE start_day = CAST(new.start_time AS DATE) AND agent_id = new.agent_id AND statistics_type_id = xstatistic_type_id1 LIMIT 1;

			IF daily_id1 IS NOT NULL THEN
				UPDATE daily_statistics SET value = value + 1 WHERE id = daily_id1;
			ELSE
				INSERT INTO daily_statistics (start_day,agent_id,statistics_type_id,value,created_at,updated_at) 
				VALUES (CAST(new.start_time AS DATE),new.agent_id,xstatistic_type_id1,1,NOW(),NOW());
			END IF;

			SET xstatistic_type_id2 = find_statistic_type('VoiceLog',CONCAT('count:',cd),TRUE);

			IF xstatistic_type_id2 IS NOT NULL THEN	
				SELECT id INTO daily_id2 FROM daily_statistics 
				WHERE start_day = CAST(new.start_time AS DATE) AND agent_id = new.agent_id AND statistics_type_id = xstatistic_type_id2 LIMIT 1;				
				IF daily_id2 IS NOT NULL THEN
					UPDATE daily_statistics SET value = value + 1 WHERE id = daily_id2;
				ELSE
					INSERT INTO daily_statistics (start_day,agent_id,statistics_type_id,value,created_at,updated_at) 
					VALUES (CAST(new.start_time AS DATE),new.agent_id,xstatistic_type_id2,1,NOW(),NOW());
				END IF;
			END IF;
	
		END IF;
	END IF;
END; 