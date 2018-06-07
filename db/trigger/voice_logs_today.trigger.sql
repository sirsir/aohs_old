DROP TRIGGER IF EXISTS `update_event_on_voicelog_today`;
--
CREATE TRIGGER `update_event_on_voicelog_today` BEFORE UPDATE ON `voice_logs_today`
FOR EACH ROW BEGIN
  IF NEW.flag IS NULL THEN
    SET NEW.flag = "";
  END IF;
END;
--
DROP TRIGGER IF EXISTS `hangup_event_on_voicelog_today`;
--
CREATE TRIGGER `hangup_event_on_voicelog_today` AFTER UPDATE ON `voice_logs_today`
FOR EACH ROW BEGIN
  DECLARE found BIGINT(20) DEFAULT 0;
  DECLARE crtdt datetime; 
  /* AFTER DISCONNECTED -> hangup cause */
  IF (OLD.hangup_cause IS NULL AND OLD.duration IS NULL) THEN
    SET crtdt = NOW();
    SELECT COUNT(0) INTO found FROM hangup_calls WHERE hangup_calls.voice_log_id = NEW.id;
    IF (found <= 0) THEN
      INSERT INTO hangup_calls(voice_log_id, call_id, start_time, created_at)
      VALUE(NEW.id, NEW.call_id, NEW.start_time, crtdt);
    END IF;
  END IF;
END;
