--FunctionName=reset_result_keywords

CREATE PROCEDURE reset_result_keywords_with_callid(icall_id VARCHAR(255))
BEGIN

	DECLARE xid BIGINT DEFAULT 0;
        DECLARE xcount INT DEFAULT 0;
        
        SELECT id INTO xid FROM voice_logs WHERE call_id = icall_id LIMIT 1;
        
        IF NOT xid IS NOT NULL THEN
        
            -- remove result keywords
            SELECT count(id) INTO xcount FROM result_keywords WHERE voice_log_id = xid LIMIT 1;
            IF xcount > 0 THEN
                DELETE FROM result_keywords WHERE voice_log_id = xid LIMIT xcount;
                SET xcount = 0;
            END IF;
            
            -- remove edit keywords
            SELECT count(id) INTO xcount FROM edit_keywords WHERE voice_log_id = xid LIMIT 1;
            IF xcount > 0 THEN
                DELETE FROM edit_keywords WHERE voice_log_id = xid LIMIT xcount;
            END IF;
        
        END IF;

END;