--FunctionName=find_statistic_type
CREATE FUNCTION find_statistic_type (model_name VARCHAR(15), valuetype VARCHAR(15), byagent INT) RETURNS INT 
BEGIN
	DECLARE statistic_id INT DEFAULT NULL;
	SELECT id INTO statistic_id 
	FROM statistics_types 
	WHERE target_model = model_name AND value_type LIKE valuetype AND by_agent = byagent LIMIT 1;
	RETURN statistic_id;
END;