--FunctionName=beginning_of_week
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