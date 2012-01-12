--TriggerName=update_weekly_and_monthly_afin
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