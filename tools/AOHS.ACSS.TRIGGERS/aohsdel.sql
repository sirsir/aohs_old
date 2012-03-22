DROP PROCEDURE IF EXISTS delete_voice_logs_data;
CREATE PROCEDURE delete_voice_logs_data()
BEGIN

	DECLARE deldays INT DEFAULT 365;
	DECLARE deldate DATETIME DEFAULT NULL;
	DECLARE delcount INT DEFAULT 0;

	SET deldays = 10;

  IF deldays > 0 THEN 
		
		SELECT DATE_SUB(NOW(), INTERVAL deldays DAY) INTO deldate;
		IF deldate IS NOT NULL THEN

			SELECT COUNT(voice_logs_1.id) INTO delcount 
			FROM voice_logs_1 
			LEFT JOIN voice_log_counters ON voice_logs_1.id = voice_log_counters.voice_log_id 
			LEFT JOIN result_keywords ON voice_logs_1.id = result_keywords.voice_log_id 
			LEFT JOIN edit_keywords ON voice_logs_1.id = edit_keywords.id 
			LEFT JOIN call_bookmarks ON voice_logs_1.id = call_bookmarks.voice_log_id
			LEFT JOIN call_informations ON voice_logs_1.id = call_informations.voice_log_id
			WHERE DATE(voice_logs_1.start_time) <= DATE(deldate);

			IF delcount > 0 THEN

				DELETE voice_logs_1, voice_log_counters, result_keywords, edit_keywords, call_bookmarks, call_informations
				FROM voice_logs_1 
				LEFT JOIN voice_log_counters ON voice_logs_1.id = voice_log_counters.voice_log_id 
				LEFT JOIN result_keywords ON voice_logs_1.id = result_keywords.voice_log_id 
				LEFT JOIN edit_keywords ON voice_logs_1.id = edit_keywords.id 
				LEFT JOIN call_bookmarks ON voice_logs_1.id = call_bookmarks.voice_log_id
				LEFT JOIN call_informations ON voice_logs_1.id = call_informations.voice_log_id
				WHERE DATE(voice_logs_1.start_time) <= DATE(deldate);

			END IF;

			SELECT DATE(deldate) AS delete_before, delcount AS deleted_records;

		END IF;
   
	END IF;

END;



DROP PROCEDURE IF EXISTS delete_statistics_data;
CREATE PROCEDURE delete_statistics_data()
BEGIN

	DECLARE deldays INT DEFAULT 60;
	DECLARE deldate DATETIME DEFAULT NULL;
	DECLARE delcount INT DEFAULT 0;

	SET deldays = 10;

  IF deldays > 0 THEN 
		
		SELECT DATE_SUB(NOW(), INTERVAL deldays DAY) INTO deldate;
		IF deldate IS NOT NULL THEN

			SELECT COUNT(id) INTO delcount 
			FROM daily_statistics 
			WHERE YEAR(start_day) <= YEAR(deldate) AND MONTH(start_day) <= MONTH(deldate);
			IF delcount > 0 THEN 
				DELETE FROM daily_statistics
				WHERE YEAR(start_day) <= YEAR(deldate) AND MONTH(start_day) <= MONTH(deldate);
			END IF;
			SELECT 'daily' AS table_name, DATE(deldate) AS delete_before, delcount AS deleted_records;

			SELECT COUNT(id) INTO delcount 
			FROM weekly_statistics 
			WHERE YEAR(start_day) <= YEAR(deldate) AND MONTH(start_day) <= MONTH(deldate);
			IF delcount > 0 THEN 
				DELETE FROM weekly_statistics
				WHERE YEAR(start_day) <= YEAR(deldate) AND MONTH(start_day) <= MONTH(deldate);
			END IF;
			SELECT 'weekly' AS table_name, DATE(deldate) AS delete_before, delcount AS deleted_records;

			SELECT COUNT(id) INTO delcount 
			FROM monthly_statistics 
			WHERE YEAR(start_day) <= YEAR(deldate) AND MONTH(start_day) <= MONTH(deldate);
			IF delcount > 0 THEN 
				DELETE FROM monthly_statistics
				WHERE YEAR(start_day) <= YEAR(deldate) AND MONTH(start_day) <= MONTH(deldate);
			END IF;
			SELECT 'monthly' AS table_name, DATE(deldate) AS delete_before, delcount AS deleted_records;

		END IF;
   
	END IF;

END;