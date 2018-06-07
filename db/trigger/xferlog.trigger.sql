DROP TRIGGER IF EXISTS `updatecallid_on_xfer`;
--
CREATE TRIGGER `updatecallid_on_xfer` BEFORE INSERT ON `xfer_logs`
FOR EACH ROW BEGIN
  DECLARE callid VARCHAR(50) default NULL; 
  DECLARE callid2 VARCHAR(50) default NULL;
  DECLARE callid_n VARCHAR(50) default NULL;
  DECLARE callid_n2 VARCHAR(50) default NULL;  
  DECLARE status int(1) default 0;     
  DECLARE CONTINUE HANDLER FOR NOT FOUND     
  BEGIN 
    SET callid = NULL;  
    SET callid_n = NULL;
  END;
         
  SELECT xfer_call_id1, xfer_call_id2 
  INTO callid, callid2 FROM xfer_logs
  WHERE xfer_call_id1 = NEW.xfer_call_id1
  ORDER BY xfer_id DESC LIMIT 1;
  
  IF callid IS NULL THEN
    SELECT xfer_call_id1, xfer_call_id2, mapping_status INTO callid_n, callid_n2, status         
    FROM xfer_logs            
    WHERE xfer_ani = NEW.xfer_ani AND xfer_extension = NEW.xfer_ani
    ORDER BY xfer_id DESC
    LIMIT 1;
    IF callid_n IS NOT NULL THEN
      IF NEW.xfer_dnis = NEW.xfer_extension THEN
        IF status = 1 THEN
          SET NEW.xfer_call_id2 = callid_n2;
          SET NEW.ext_tranfer ='0';                
        ELSE
          SET NEW.xfer_call_id2 = callid_n;
          SET NEW.ext_tranfer ='0';   
        END IF;
      ELSE
        SET NEW.xfer_call_id2 = '1';
        SET NEW.ext_tranfer ='0';                  
      END IF;
    ELSE
      SET NEW.xfer_call_id2 = '1';
      SET NEW.ext_tranfer ='1';             
    END IF;
  ELSE
    IF callid2 = '1' THEN 
      SET NEW.xfer_call_id2 = callid;
      SET NEW.ext_tranfer ='0';              
    ELSE
      SET NEW.xfer_call_id2 = callid2;
      SET NEW.ext_tranfer ='0';
    END IF;
    SET NEW.mapping_status = 1;
  END IF;
END;
--
DROP TRIGGER IF EXISTS `afterinsert_on_xfer`;
--
CREATE TRIGGER `afterinsert_on_xfer` AFTER INSERT ON `xfer_logs`
FOR EACH ROW BEGIN
  DECLARE pani VARCHAR(50) default NULL;
  UPDATE voice_logs_today
  SET ori_call_id=NEW.xfer_call_id2,xfer_ani= NEW.xfer_ani,xfer_dnis=NEW.xfer_dnis
  WHERE call_id = NEW.xfer_call_id1 AND xfer_ani IS NULL AND xfer_dnis IS NULL;

  UPDATE voice_logs_today SET flag_transfer='Conn', ori_call_id='1'
  WHERE call_id = NEW.xfer_call_id2;

  UPDATE voice_logs_today SET ori_call_id = NULL
  WHERE call_id = NEW.xfer_call_id1 AND ori_call_id = '1';
  IF NEW.ext_tranfer='1' THEN
    UPDATE voice_logs_today SET voice_logs_today.ext_tranfer='true'
    WHERE call_id = NEW.xfer_call_id1;
  ELSE
    UPDATE voice_logs_today SET ext_tranfer='false'
    WHERE call_id = NEW.xfer_call_id1;
  END IF;
  IF NEW.msg_type IS NULL THEN
    UPDATE voice_logs_today
    SET log_trans_ani=concat(ifnull(log_trans_ani,''),NEW.xfer_ani,','),log_trans_dnis=concat(ifnull(log_trans_dnis,''),NEW.xfer_dnis),log_trans_extension=concat(ifnull(log_trans_extension,''),NEW.xfer_ani,',')
    WHERE call_id=NEW.xfer_call_id2;
  ELSE
    UPDATE voice_logs_today SET log_trans_ani=concat(NEW.xfer_ani,',',ifnull(log_trans_ani,'')),log_trans_dnis=concat(ifnull(log_trans_dnis,''),NEW.xfer_dnis,','),log_trans_extension=concat(ifnull(log_trans_extension,''),NEW.xfer_extension,',')
    WHERE call_id=NEW.xfer_call_id2;
  END IF;
END;
--
DROP TRIGGER IF EXISTS `afterinsert_on_dsplog`;
--
CREATE TRIGGER `afterinsert_on_dsplog` AFTER INSERT ON `display_logs`
FOR EACH ROW BEGIN
  DECLARE call_id VARCHAR(50) default NULL;
  IF((ifnull(NEW.number2,'')<>'' AND NEW.call_direction= 'i') OR (NEW.transfer='true')) THEN
    UPDATE voice_logs_today
    SET voice_logs_today.ani=concat('(', ifnull((SELECT distinct ifnull(display_logs.number1,'') FROM display_logs WHERE display_logs.call_id = new.call_id and IFNULL(display_logs.number1,'')<>'' ORDER BY display_logs.uniqueId DESC LIMIT 1),''),')',IFNULL((SELECT DISTINCT IFNULL(display_logs.number2,'') FROM display_logs WHERE display_logs.call_id = new.call_id AND IFNULL(display_logs.number2,'')<>'' ORDER BY display_logs.uniqueId DESC LIMIT 1),''))
    WHERE voice_logs_today.call_id = new.call_id AND voice_logs_today.ext_tranfer = 'true';
  END IF;
END;
