--FunctionName=get_active_logger_id
CREATE FUNCTION get_active_logger_id(logger_id INT)
 RETURNS INT
BEGIN
	DECLARE is_current INT DEFAULT FALSE;
	IF (SELECT default_value FROM configurations WHERE variable = 'activeId' LIMIT 1) = logger_id THEN
		SET is_current = TRUE;
	END IF;
	RETURN is_current;
END;