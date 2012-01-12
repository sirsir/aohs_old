--FunctionName=end_of_month
CREATE FUNCTION end_of_month (`cdate` DATE)
 RETURNS DATE
BEGIN
	DECLARE eom DATE DEFAULT NULL;
	DECLARE start_day INT DEFAULT 1;
	
	SET eom =  CAST(DATE_ADD(cdate,INTERVAL DAY(LAST_DAY(cdate)) - DAYOFMONTH(cdate) DAY) AS DATE);
	RETURN eom;
END;