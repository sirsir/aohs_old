--TriggerName=add_voicelogs_1_statistics_afup
 
CREATE TRIGGER add_voicelogs_1_statistics_afup AFTER UPDATE ON voice_logs_today_1
FOR EACH ROW BEGIN
	DECLARE trf_count INT DEFAULT 0;
	DECLARE trf_in INT DEFAULT 0;
	DECLARE trf_out INT DEFAULT 0;
	DECLARE trf_duration INT DEFAULT 0;
	DECLARE xori_id INT DEFAULT NULL;
	DECLARE xmain_callid VARCHAR(50) DEFAULT NULL;
	
	IF get_active_logger_id(1) THEN
		IF (new.ori_call_id = '1' or new.ori_call_id = '' or new.ori_call_id is NULL) THEN
			-- main call
			IF new.duration > 0 THEN
				SET xmain_callid = new.call_id;
				SET xori_id = new.id;
			END IF;
		ELSE
			-- sub call
			SELECT id,call_id INTO xori_id,xmain_callid 
			FROM voice_logs_today_1 WHERE call_id = new.ori_call_id LIMIT 1;
		END IF;
		
		IF xmain_callid IS NOT NULL AND xori_id IS NOT NULL THEN
			SELECT COUNT(id) AS transfer_count, SUM(IF(call_direction = 'i',1,0)) AS call_in, SUM(IF(call_direction = 'o',1,0)) AS call_out, SUM(duration) AS call_duration 
			INTO trf_count, trf_in, trf_out, trf_duration 
			FROM voice_logs_today_1 WHERE ori_call_id = xmain_callid;	
			
			SET trf_count = IFNULL(trf_count,0);
			SET trf_in = IFNULL(trf_in,0);
			SET trf_out = IFNULL(trf_out,0);
			SET trf_duration = IFNULL(trf_duration,0);
			
			UPDATE voice_log_counters SET transfer_call_count = trf_count, transfer_in_count = trf_in, transfer_out_count = trf_out, transfer_duration = trf_duration  WHERE voice_log_id = xori_id LIMIT 1;		
		END IF;		
	END IF;
END;