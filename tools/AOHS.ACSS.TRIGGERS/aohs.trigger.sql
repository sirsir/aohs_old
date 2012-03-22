
-- VoiceLog

DROP TRIGGER IF EXISTS add_voicelogs_1_statistics_afins;
CREATE TRIGGER add_voicelogs_1_statistics_afins AFTER INSERT ON voice_logs_today_1
FOR EACH ROW BEGIN

	DECLARE xstatistic_type_id1 INT DEFAULT NULL;
	DECLARE xstatistic_type_id2 INT DEFAULT NULL;
	DECLARE daily_id1 INT DEFAULT NULL;
	DECLARE daily_id2 INT DEFAULT NULL;	
	DECLARE cd VARCHAR(1);

	INSERT INTO voice_log_counters(voice_log_id,keyword_count,ngword_count,mustword_count,bookmark_count,created_at,updated_at) 
	VALUES (new.id,0,0,0,0,NOW(),NOW());

	CASE new.call_direction
	WHEN 'i' THEN 
		SET cd = 'i';
	WHEN 'o' THEN 
		SET cd = 'o';
	ELSE 
		SET cd = 'e';
	END CASE;
	
	IF new.agent_id IS NOT NULL AND new.start_time IS NOT NULL THEN

		SET xstatistic_type_id1 = find_statistic_type('VoiceLog','count',TRUE);

		SELECT id INTO daily_id1 FROM daily_statistics 
		WHERE start_day = CAST(new.start_time AS DATE) AND agent_id = new.agent_id AND statistics_type_id = xstatistic_type_id1 LIMIT 1;

		IF daily_id1 IS NOT NULL THEN
			UPDATE daily_statistics SET value = value + 1 WHERE id = daily_id1 LIMIT 1;
		ELSE
			INSERT INTO daily_statistics (start_day,agent_id,statistics_type_id,value,created_at,updated_at) 
			VALUES (CAST(new.start_time AS DATE),new.agent_id,xstatistic_type_id1,1,NOW(),NOW());
		END IF;

		SET xstatistic_type_id2 = find_statistic_type('VoiceLog',CONCAT('count:',cd),TRUE);

		IF xstatistic_type_id2 IS NOT NULL THEN	
			SELECT id INTO daily_id2 FROM daily_statistics 
			WHERE start_day = CAST(new.start_time AS DATE) AND agent_id = new.agent_id AND statistics_type_id = xstatistic_type_id2 LIMIT 1;				
			IF daily_id2 IS NOT NULL THEN
				UPDATE daily_statistics SET value = value + 1 WHERE id = daily_id2 LIMIT 1;
			ELSE
				INSERT INTO daily_statistics (start_day,agent_id,statistics_type_id,value,created_at,updated_at) 
				VALUES (CAST(new.start_time AS DATE),new.agent_id,xstatistic_type_id2,1,NOW(),NOW());
			END IF;
		END IF;

	END IF;

END; 

-- ResultKeyword

DROP TRIGGER IF EXISTS count_statistics_for_result_insert;
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

	-- if new result keyword 
	IF new.keyword_id IS NOT NULL AND new.edit_status IS NULL THEN
				
		SELECT keyword_type INTO xkeyword_type FROM keywords WHERE id = new.keyword_id;
		
		SELECT id,CAST(start_time AS DATE),agent_id INTO xvoice_id,xdate,xuser_id 
		FROM voice_logs_1 WHERE id = new.voice_log_id LIMIT 1;
		
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

		END IF;

	END IF;

END;

DROP TRIGGER IF EXISTS count_statistics_for_result_change; 
CREATE TRIGGER count_statistics_for_result_change AFTER UPDATE ON result_keywords
FOR EACH ROW BEGIN
		
	DECLARE xkeyword_type CHAR DEFAULT NULL;
	DECLARE xdate DATE DEFAULT NULL;
	DECLARE xvoice_id INT DEFAULT NULL;
	DECLARE xuser_id INT DEFAULT 0;
	DECLARE xstatistic_type_id1 INT DEFAULT NULL;
	DECLARE xstatistic_type_id2 INT DEFAULT NULL;	
	DECLARE xori_id INT DEFAULT NULL;
	DECLARE xori_call_id VARCHAR(255) DEFAULT NULL;
	
	-- IF old.edit_status != new.edit_status THEN
	
		-- update if edit staus changed
		IF new.edit_status = 'd' OR new.edit_status = 'e' THEN
			
			SELECT keyword_type INTO xkeyword_type FROM keywords WHERE id = new.keyword_id;
			SELECT id,CAST(start_time AS DATE),agent_id INTO xvoice_id,xdate,xuser_id FROM voice_logs_1 WHERE id = new.voice_log_id LIMIT 1;	
			
			IF xkeyword_type IS NOT NULL AND xdate IS NOT NULL AND xvoice_id IS NOT NULL THEN

				-- daily keywords by keyword
				SET xstatistic_type_id1 = find_statistic_type('ResultKeyword','sum',FALSE);	
				IF xstatistic_type_id1 THEN
					UPDATE daily_statistics SET value = value - 1 
					WHERE keyword_id = new.keyword_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id1 LIMIT 1;
				END IF;
				
				-- daily keywords agent by agent/keyword_type
				SET xstatistic_type_id2 = find_statistic_type('ResultKeyword',CONCAT('sum:',xkeyword_type),TRUE);	
				IF xstatistic_type_id2 IS NOT NULL THEN
					UPDATE daily_statistics SET value = value - 1 
					WHERE agent_id = xuser_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id2 LIMIT 1;
				END IF;

				-- voice_logs_counter 
				CASE xkeyword_type
				WHEN 'n' THEN
					UPDATE voice_log_counters SET keyword_count = keyword_count - 1, ngword_count = ngword_count - 1 
					WHERE voice_log_id = new.voice_log_id LIMIT 1;
				WHEN 'm' THEN 
					UPDATE voice_log_counters SET keyword_count = keyword_count - 1, mustword_count = mustword_count - 1 
					WHERE voice_log_id = new.voice_log_id LIMIT 1;
				END CASE;

			END IF;
			
		END IF;	
	-- END IF;

END;

DROP TRIGGER IF EXISTS count_statistics_for_result_del;
CREATE TRIGGER count_statistics_for_result_del AFTER DELETE ON result_keywords
FOR EACH ROW BEGIN

	DECLARE xkeyword_type CHAR DEFAULT NULL;
	DECLARE xdate DATE DEFAULT NULL;
	DECLARE xvoice_id INT DEFAULT NULL;
	DECLARE xuser_id INT DEFAULT 0;
	DECLARE xstatistic_type_id1 INT DEFAULT NULL;
	DECLARE xstatistic_type_id2 INT DEFAULT NULL;
	DECLARE xstatistic_id1 INT DEFAULT NULL;	
	DECLARE xstatistic_id2 INT DEFAULT NULL;

	-- if new result keyword 
	IF old.keyword_id IS NOT NULL and old.edit_status IS NULL THEN
    
	    SELECT keyword_type INTO xkeyword_type FROM keywords WHERE id = old.keyword_id;
	    
        SELECT id,CAST(start_time AS DATE),agent_id INTO xvoice_id,xdate,xuser_id 
        FROM voice_logs_1 WHERE id = old.voice_log_id LIMIT 1;
	
        IF xkeyword_type IS NOT NULL AND xdate IS NOT NULL AND old.voice_log_id IS NOT NULL THEN
        
            -- daily keywords by keyword
            SET xstatistic_type_id1 = find_statistic_type('ResultKeyword','sum',FALSE);
            IF xstatistic_type_id1 IS NOT NULL THEN
                    SELECT id INTO xstatistic_id1 FROM daily_statistics 
                    WHERE keyword_id = old.keyword_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id1 LIMIT 1;
                    IF xstatistic_id1 IS NULL THEN
                            INSERT INTO daily_statistics(start_day,keyword_id,statistics_type_id,value,created_at,updated_at) 
                            VALUES (xdate,old.keyword_id,xstatistic_type_id1,0,NOW(),NOW());
                    ELSE
                            UPDATE daily_statistics SET value = value - 1, updated_at = NOW() WHERE id = xstatistic_id1 LIMIT 1;
                    END IF;
            END IF;

            -- daily keywords agent by agent/keyword_type
            SET xstatistic_type_id2 = find_statistic_type('ResultKeyword',CONCAT('sum:',xkeyword_type),TRUE);	
            IF xstatistic_type_id2 IS NOT NULL THEN
                    SELECT id INTO xstatistic_id2 FROM daily_statistics 
                    WHERE agent_id = xuser_id AND start_day = xdate AND statistics_type_id = xstatistic_type_id2 LIMIT 1;
                    IF xstatistic_id2 IS NULL THEN
                            INSERT INTO daily_statistics(start_day,agent_id,statistics_type_id,value,created_at,updated_at) 
                            VALUES (xdate,xuser_id,xstatistic_type_id2,0,NOW(),NOW());							
                    ELSE
                            UPDATE daily_statistics SET value = value - 1, updated_at = NOW() WHERE id = xstatistic_id2 LIMIT 1;
                    END IF;
            END IF;

            -- voice_logs_counter 
            CASE xkeyword_type 
            WHEN 'n' THEN
                    UPDATE voice_log_counters SET keyword_count = keyword_count - 1, ngword_count = ngword_count - 1 WHERE voice_log_id = old.voice_log_id LIMIT 1;
            WHEN 'm' THEN 
                    UPDATE voice_log_counters SET keyword_count = keyword_count - 1, mustword_count = mustword_count - 1 WHERE voice_log_id = old.voice_log_id LIMIT 1;
            END CASE;

        END IF;

	END IF;

END;

-- DailyStatistics

DROP TRIGGER IF EXISTS update_weekly_and_monthly_afin;
CREATE TRIGGER update_weekly_and_monthly_afin AFTER INSERT ON `daily_statistics` 
FOR EACH ROW
BEGIN
	DECLARE xtotal INT DEFAULT 0;
	DECLARE bod DATE DEFAULT NULL;
	DECLARE eod DATE DEFAULT NULL;
	DECLARE rec_id INT DEFAULT NULL;

	-- weekly 

	SET bod = beginning_of_week(new.start_day);
	SET eod = end_of_week(new.start_day);

	IF bod IS NOT NULL AND eod IS NOT NULL AND new.statistics_type_id IS NOT NULL THEN
		IF new.agent_id IS NOT NULL AND new.keyword_id IS NOT NULL THEN
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.agent_id = new.agent_id AND d.keyword_id = new.keyword_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		ELSEIF new.agent_id IS NULL THEN 
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.keyword_id = new.keyword_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		ELSE
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.agent_id = new.agent_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);		
		END IF;

		IF xtotal IS NULL THEN 
			SET xtotal = 0;
		END IF;
		
		IF new.agent_id IS NOT NULL AND new.keyword_id IS NOT NULL THEN
			SELECT id INTO rec_id FROM weekly_statistics w WHERE w.agent_id = new.agent_id AND w.keyword_id = new.keyword_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;
		ELSEIF new.agent_id IS NULL THEN 
			SELECT id INTO rec_id FROM weekly_statistics w WHERE w.keyword_id = new.keyword_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;		
		ELSE
			SELECT id INTO rec_id FROM weekly_statistics w WHERE w.agent_id = new.agent_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;		
		END IF;

		IF rec_id IS NULL THEN
			INSERT INTO weekly_statistics(start_day,agent_id,keyword_id,statistics_type_id,value,cweek,cwyear,created_at,updated_at)
			VALUES(bod,new.agent_id,new.keyword_id,new.statistics_type_id,xtotal,WEEK(bod),YEAR(bod),NOW(),NOW());
		ELSE
			UPDATE weekly_statistics SET value = xtotal, updated_at = NOW() WHERE id = rec_id LIMIT 1;
		END IF;
	END IF;

	-- monthly

	SET bod = beginning_of_month(new.start_day);
	SET eod = end_of_month(new.start_day);

	IF bod IS NOT NULL AND eod IS NOT NULL AND new.statistics_type_id IS NOT NULL THEN
		IF new.agent_id IS NOT NULL AND new.keyword_id IS NOT NULL THEN
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.agent_id = new.agent_id AND d.keyword_id = new.keyword_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		ELSEIF new.agent_id IS NULL THEN 
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.keyword_id = new.keyword_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		ELSE
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.agent_id = new.agent_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		END IF;

		IF xtotal IS NULL THEN 
			SET xtotal = 0;
		END IF;
		
		IF new.agent_id IS NOT NULL AND new.keyword_id IS NOT NULL THEN
			SELECT id INTO rec_id FROM monthly_statistics w WHERE w.agent_id = new.agent_id AND w.keyword_id = new.keyword_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;
		ELSEIF new.agent_id IS NULL THEN 
			SELECT id INTO rec_id FROM monthly_statistics w WHERE w.keyword_id = new.keyword_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;		
		ELSE
			SELECT id INTO rec_id FROM monthly_statistics w WHERE w.agent_id = new.agent_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;		
		END IF;

		IF rec_id IS NULL THEN
			INSERT INTO monthly_statistics(start_day,agent_id,keyword_id,statistics_type_id,value,created_at,updated_at)
			VALUES(bod,new.agent_id,new.keyword_id,new.statistics_type_id,xtotal,NOW(),NOW());
		ELSE
			UPDATE monthly_statistics SET value = xtotal WHERE id = rec_id LIMIT 1;
		END IF;	
	END IF;

END;

DROP TRIGGER IF EXISTS update_weekly_and_monthly_afup;
CREATE TRIGGER update_weekly_and_monthly_afup AFTER UPDATE ON `daily_statistics` 
FOR EACH ROW
BEGIN
	DECLARE xtotal INT DEFAULT 0;
	DECLARE xtotal2 INT DEFAULT 0;	
	DECLARE bod DATE DEFAULT NULL;
	DECLARE eod DATE DEFAULT NULL;
	DECLARE rec_id INT DEFAULT NULL;
	
	-- weekly 
		
	SET bod = beginning_of_week(new.start_day);
	SET eod = end_of_week(new.start_day);

	IF bod IS NOT NULL AND eod IS NOT NULL AND new.statistics_type_id IS NOT NULL THEN
		IF new.agent_id IS NOT NULL AND new.keyword_id IS NOT NULL THEN
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.agent_id = new.agent_id AND d.keyword_id = new.keyword_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		ELSEIF new.agent_id IS NULL THEN 
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.keyword_id = new.keyword_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		ELSE
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.agent_id = new.agent_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);		
		END IF;

		IF xtotal IS NULL THEN 
			SET xtotal = 0;
		END IF;
		
		IF new.agent_id IS NOT NULL AND new.keyword_id IS NOT NULL THEN
			SELECT id,value INTO rec_id,xtotal2 FROM weekly_statistics w WHERE w.agent_id = new.agent_id AND w.keyword_id = new.keyword_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;
		ELSEIF new.agent_id IS NULL THEN 
			SELECT id,value INTO rec_id,xtotal2 FROM weekly_statistics w WHERE w.keyword_id = new.keyword_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;		
		ELSE
			SELECT id,value INTO rec_id,xtotal2 FROM weekly_statistics w WHERE w.agent_id = new.agent_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;		
		END IF;
		IF xtotal != xtotal2 THEN		
			IF rec_id IS NULL THEN
				INSERT INTO weekly_statistics(start_day,agent_id,keyword_id,statistics_type_id,value,cweek,cwyear,created_at,updated_at)
				VALUES(bod,new.agent_id,new.keyword_id,new.statistics_type_id,xtotal,WEEK(bod),YEAR(bod),NOW(),NOW());
			ELSE
				UPDATE weekly_statistics SET value = xtotal, updated_at = NOW() WHERE id = rec_id LIMIT 1;
			END IF;
		END IF;
	END IF;

	-- monthly

	SET bod = beginning_of_month(new.start_day);
	SET eod = end_of_month(new.start_day);

	IF bod IS NOT NULL AND eod IS NOT NULL AND new.statistics_type_id IS NOT NULL THEN
		IF new.agent_id IS NOT NULL AND new.keyword_id IS NOT NULL THEN
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.agent_id = new.agent_id AND d.keyword_id = new.keyword_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		ELSEIF new.agent_id IS NULL THEN 
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.keyword_id = new.keyword_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		ELSE
			SELECT sum(d.value) as total INTO xtotal 
			FROM daily_statistics d 
			WHERE d.agent_id = new.agent_id AND d.statistics_type_id = new.statistics_type_id AND (d.start_day >= bod AND d.start_day <= eod);
		END IF;

		IF xtotal IS NULL THEN 
			SET xtotal = 0;
		END IF;
		
		IF new.agent_id IS NOT NULL AND new.keyword_id IS NOT NULL THEN
			SELECT id,value INTO rec_id,xtotal2 FROM monthly_statistics w WHERE w.agent_id = new.agent_id AND w.keyword_id = new.keyword_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;
		ELSEIF new.agent_id IS NULL THEN 
			SELECT id,value INTO rec_id,xtotal2 FROM monthly_statistics w WHERE w.keyword_id = new.keyword_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;		
		ELSE
			SELECT id,value INTO rec_id,xtotal2 FROM monthly_statistics w WHERE w.agent_id = new.agent_id AND w.statistics_type_id = new.statistics_type_id AND w.start_day = bod LIMIT 1;		
		END IF;
		IF xtotal != xtotal2 THEN
			IF rec_id IS NULL THEN
				INSERT INTO monthly_statistics(start_day,agent_id,keyword_id,statistics_type_id,value,created_at,updated_at)
				VALUES(bod,new.agent_id,new.keyword_id,new.statistics_type_id,xtotal,NOW(),NOW());
			ELSE
				UPDATE monthly_statistics SET value = xtotal WHERE id = rec_id LIMIT 1;
			END IF;	
		END IF;
	END IF;

END;