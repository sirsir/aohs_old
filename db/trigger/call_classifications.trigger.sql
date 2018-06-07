DROP TRIGGER IF EXISTS `update_counter_cache1_on_call_class`;
--
CREATE TRIGGER `update_counter_cache1_on_call_class` AFTER INSERT ON `call_classifications`
FOR EACH ROW BEGIN 
  DECLARE xid BIGINT;
  DECLARE xcount INT DEFAULT 0;
  SELECT call_classifications.voice_log_id, COUNT(0)
  INTO xid, xcount
  FROM call_classifications
  WHERE call_classifications.flag <> "D" AND call_classifications.voice_log_id = NEW.voice_log_id;
  IF ((xcount > 0) AND NOT EXISTS(SELECT 1 FROM voice_log_counters WHERE voice_log_id = NEW.voice_log_id LIMIT 1)) THEN
    INSERT INTO voice_log_counters(voice_log_id, counter_type, valu, updated_at)
    VALUES(NEW.voice_log_id, 10, xcount, NOW());
  ELSE
    UPDATE voice_log_counters SET valu = xcount WHERE voice_log_id = NEW.voice_log_id AND counter_type = 10 LIMIT 1;
  END IF;
END;
--
DROP TRIGGER IF EXISTS `update_counter_cache2_on_call_class`;
--
CREATE TRIGGER `update_counter_cache2_on_call_class` AFTER UPDATE ON `call_classifications`
FOR EACH ROW BEGIN 
  DECLARE xid BIGINT;
  DECLARE xcount INT DEFAULT 0;
  SELECT call_classifications.voice_log_id, COUNT(0)
  INTO xid, xcount
  FROM call_classifications
  WHERE call_classifications.flag <> "D" AND call_classifications.voice_log_id = NEW.voice_log_id;
  IF ((xcount > 0) AND NOT EXISTS(SELECT 1 FROM voice_log_counters WHERE voice_log_id = NEW.voice_log_id LIMIT 1)) THEN
    INSERT INTO voice_log_counters(voice_log_id, counter_type, valu, updated_at)
    VALUES(NEW.voice_log_id, 10, xcount, NOW());
  ELSE
    UPDATE voice_log_counters SET valu = xcount WHERE voice_log_id = NEW.voice_log_id AND counter_type = 10 LIMIT 1;
  END IF;
END;