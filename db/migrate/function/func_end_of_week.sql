--FunctionName=end_of_week
CREATE FUNCTION end_of_week (`cdate` DATE)
 RETURNS DATE 
BEGIN
	DECLARE eow DATE DEFAULT NULL;	
	SET eow =  DATE_ADD(beginning_of_week(cdate),INTERVAL 6 DAY);
	RETURN eow;
END;