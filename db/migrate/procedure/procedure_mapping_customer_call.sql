--ProcedureName=mapping_customer
  
CREATE PROCEDURE mapping_customer (xvoice_log_id INT, phone VARCHAR(20))
BEGIN
  
	DECLARE xphone_id INT DEFAULT NULL;
	DECLARE xcustomer_id INT DEFAULT NULL;
	DECLARE vlc_id INT DEFAULT NULL;
	DECLARE keyphone VARCHAR(20) DEFAULT NULL;
	
	IF (LENGTH(phone) >= 6) THEN
		IF (SUBSTR(phone,1,1) = '9') THEN
			SET keyphone = SUBSTR(phone,2);
		ELSE
			SET keyphone = phone;
		END IF;
	END IF;
    
	IF keyphone IS NOT NULL THEN
		SELECT c.id,p.id INTO xcustomer_id, xphone_id 
		FROM customers c JOIN customer_numbers p 
		ON c.id = p.customer_id
		WHERE (p.number = CONCAT('0',keyphone))
		ORDER BY c.updated_at DESC, p.updated_at DESC LIMIT 1;
	END IF;
	
	IF xphone_id IS NOT NULL AND xcustomer_id IS NOT NULL THEN
		-- look up customer
		SELECT v.id INTO vlc_id  
		FROM voice_log_customers v 
		WHERE v.customer_id = xcustomer_id AND v.voice_log_id = xvoice_log_id LIMIT 1;

		IF vlc_id IS NULL THEN
			INSERT INTO voice_log_customers(voice_log_id,customer_id) VALUES(xvoice_log_id,customer_id);
		ELSE
			UPDATE voice_log_customers SET customer_id = xcustomer_id WHERE id = xvoice_log_id;
		END IF;
		
		-- look up car number
		SET @a = xvoice_log_id;
		INSERT INTO voice_log_cars(voice_log_id,car_number_id)
		SELECT @a as voice_log_id, id as car_number_id FROM car_numbers WHERE customer_id = xcustomer_id AND (flag NOT LIKE 'd' OR flag IS NULL);
	
	END IF;

END;