-- FunctionName=beginning_of_month
DROP FUNCTION IF EXISTS beginning_of_month;
CREATE FUNCTION beginning_of_month (`cdate` DATE)
 RETURNS DATE
BEGIN
	DECLARE bom DATE DEFAULT NULL;
	DECLARE start_day INT DEFAULT 1;
	
	SET bom =  CAST(DATE_SUB(cdate,INTERVAL DAYOFMONTH(cdate) - start_day DAY) AS DATE);
	RETURN bom;
END;

-- FunctionName=beginning_of_week
DROP FUNCTION IF EXISTS beginning_of_week;
CREATE FUNCTION beginning_of_week (`cdate` DATE)
 RETURNS DATE
BEGIN
	DECLARE bow DATE DEFAULT NULL;
	DECLARE start_day INT DEFAULT 0;
	
	-- beginning of week is monday 
	-- (0 = Monday, 1 = Tuesday, … 6 = Sunday)
	SET bow =  CAST(DATE_SUB(cdate,INTERVAL WEEKDAY(cdate) + start_day DAY) AS DATE);
	RETURN bow;
END;

-- FunctionName=end_of_month
DROP FUNCTION IF EXISTS end_of_month;
CREATE FUNCTION end_of_month (`cdate` DATE)
 RETURNS DATE
BEGIN
	DECLARE eom DATE DEFAULT NULL;
	DECLARE start_day INT DEFAULT 1;
	
	SET eom =  CAST(DATE_ADD(cdate,INTERVAL DAY(LAST_DAY(cdate)) - DAYOFMONTH(cdate) DAY) AS DATE);
	RETURN eom;
END;

-- FunctionName=end_of_week
DROP FUNCTION IF EXISTS end_of_week;
CREATE FUNCTION end_of_week (`cdate` DATE)
 RETURNS DATE 
BEGIN
	DECLARE eow DATE DEFAULT NULL;	
	SET eow =  DATE_ADD(beginning_of_week(cdate),INTERVAL 6 DAY);
	RETURN eow;
END;

-- FunctionName=find_statistic_type
DROP FUNCTION IF EXISTS find_statistic_type;
CREATE FUNCTION find_statistic_type (model_name VARCHAR(15), valuetype VARCHAR(15), byagent INT) RETURNS INT 
BEGIN
	DECLARE statistic_id INT DEFAULT NULL;
	SELECT id INTO statistic_id 
	FROM statistics_types 
	WHERE target_model = model_name AND value_type LIKE valuetype AND by_agent = byagent LIMIT 1;
	RETURN statistic_id;
END;

DROP PROCEDURE IF EXISTS reset_result_keywords_of_callid;
CREATE PROCEDURE reset_result_keywords_of_callid(xcall_id VARCHAR(255))
BEGIN

	DECLARE xid BIGINT DEFAULT NULL;
    DECLARE xcount INT DEFAULT 0;
    
    SELECT id INTO xid FROM voice_logs_1 WHERE call_id = xcall_id LIMIT 1;
    
    IF xid IS NOT NULL THEN
    
        -- remove result keywords
        SELECT count(id) INTO xcount FROM result_keywords WHERE voice_log_id = xid LIMIT 1;
        IF xcount > 0 THEN
            DELETE FROM result_keywords WHERE voice_log_id = xid LIMIT 100;
            SET xcount = 0;
        END IF;
        
        -- remove edit keywords
        SELECT count(id) INTO xcount FROM edit_keywords WHERE voice_log_id = xid LIMIT 1;
        IF xcount > 0 THEN
            DELETE FROM edit_keywords WHERE voice_log_id = xid LIMIT 100;
        END IF;
    
    END IF;

END; 

DROP PROCEDURE IF EXISTS reset_result_keywords_of_voiceid;
CREATE PROCEDURE reset_result_keywords_of_voiceid(xvoice_id BIGINT)
BEGIN

	DECLARE xid BIGINT DEFAULT NULL;
    DECLARE xcount INT DEFAULT 0;
    
    SELECT id INTO xid FROM voice_logs_1 WHERE id = xvoice_id LIMIT 1;
    
    IF xid IS NOT NULL THEN
    
        -- remove result keywords
        SELECT count(id) INTO xcount FROM result_keywords WHERE voice_log_id = xid LIMIT 1;
        IF xcount > 0 THEN
            DELETE FROM result_keywords WHERE voice_log_id = xid LIMIT 100;
            SET xcount = 0;
        END IF;
        
        -- remove edit keywords
        SELECT count(id) INTO xcount FROM edit_keywords WHERE voice_log_id = xid LIMIT 1;
        IF xcount > 0 THEN
            DELETE FROM edit_keywords WHERE voice_log_id = xid LIMIT 100;
        END IF;
    
    END IF;

END;