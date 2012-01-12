--FunctionName=beginning_of_month
CREATE FUNCTION beginning_of_month (`cdate` DATE)
 RETURNS DATE
BEGIN
	DECLARE bom DATE DEFAULT NULL;
	DECLARE start_day INT DEFAULT 1;
	
	SET bom =  CAST(DATE_SUB(cdate,INTERVAL DAYOFMONTH(cdate) - start_day DAY) AS DATE);
	RETURN bom;
END;