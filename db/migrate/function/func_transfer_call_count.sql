--FunctionName=transfer_call_count
CREATE FUNCTION transfer_call_count (`c_id` VARCHAR(255))
 RETURNS int
BEGIN
	DECLARE total INTEGER DEFAULT 0;
	
	SELECT COUNT(id) as transfer_count INTO total FROM voice_logs 
	WHERE ori_call_id = c_id;

	RETURN total;
END;