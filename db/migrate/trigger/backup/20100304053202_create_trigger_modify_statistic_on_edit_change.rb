class CreateTriggerModifyStatisticOnEditChange < ActiveRecord::Migration
  def self.up
#   execute "DROP TRIGGER IF EXISTS modify_statistics_when_edit_change"
   execute <<SQL
   CREATE TRIGGER modify_statistics_when_edit_change AFTER UPDATE ON edit_keywords
    FOR EACH ROW BEGIN

            DECLARE old_keyword_type VARCHAR(1);
         DECLARE new_keyword_type VARCHAR(1);
         DECLARE k_type VARCHAR(1);
         DECLARE s_time  DATETIME;
         DECLARE r_time  DATE;
         DECLARE s2_type INT;
         DECLARE s_type  INT;
         DECLARE daily_value  INT;
         DECLARE agent   INT;
         DECLARE total_must INT;
         DECLARE total_ng INT;
         DECLARE total_keyword INT;
         SET total_keyword = 0;
         SET total_ng = 0;
         SET total_must = 0;
        IF new.edit_status = 'd' THEN
           SELECT id INTO s2_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum' AND by_agent = 0 LIMIT 1;
              IF EXISTS(SELECT id FROM keywords WHERE id = new.keyword_id) THEN
                 SELECT keyword_type INTO k_type FROM keywords WHERE id = new.keyword_id;
              END IF;
              IF (SELECT default_value FROM configurations WHERE variable = 'activeId' LIMIT 1) = '1' THEN
                  IF EXISTS(SELECT id FROM voice_logs_1 WHERE id = new.voice_log_id) THEN
                     SELECT agent_id,start_time INTO agent,s_time FROM voice_logs_1 WHERE id = new.voice_log_id;
                     SET r_time =  CAST(s_time AS DATE);
                  END IF;
              ELSE
                  IF EXISTS(SELECT id FROM voice_logs_2 WHERE id = new.voice_log_id) THEN
                     SELECT agent_id,start_time INTO agent,s_time FROM voice_logs_2 WHERE id = new.voice_log_id;
                     SET r_time =  CAST(s_time AS DATE);
                  END IF;
              END IF;
              IF k_type IS NOT NULL AND r_time IS NOT NULL THEN
                 CASE k_type
                 WHEN 'n' THEN
                          BEGIN
                          SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:n';
		          IF EXISTS(SELECT id FROM voice_log_counters WHERE voice_log_id = new.voice_log_id) THEN
                             SELECT keyword_count,ngword_count INTO total_keyword,total_ng
                             FROM voice_log_counters WHERE voice_log_id = new.voice_log_id;
                             SET total_keyword = total_keyword - 1;
                             SET total_ng = total_ng - 1;
                             UPDATE voice_log_counters SET keyword_count = total_keyword,ngword_count = total_ng WHERE voice_log_id = new.voice_log_id;
                          END IF;
                          END;
                 WHEN 'm' THEN
                          BEGIN
                          SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:m';
		          IF EXISTS(SELECT id FROM voice_log_counters WHERE voice_log_id = new.voice_log_id) THEN
                             SELECT keyword_count,mustword_count INTO total_keyword,total_must
                             FROM voice_log_counters WHERE voice_log_id = new.voice_log_id;
                             SET total_keyword = total_keyword - 1;
                             SET total_must = total_must - 1;
                             UPDATE voice_log_counters SET keyword_count = total_keyword,mustword_count = total_must WHERE voice_log_id = new.voice_log_id;
                             END IF;
                          END;
                 WHEN 'a' THEN SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:a';
                 END CASE;
                 SET daily_value = 0;
                 IF agent IS NOT NULL AND agent > 0 AND r_time IS NOT NULL THEN
                 IF EXISTS(SELECT id FROM daily_statistics WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type) THEN
                    SELECT d.value INTO daily_value FROM daily_statistics d WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type;
                    SET daily_value = daily_value - 1;
                    UPDATE daily_statistics d SET d.value = daily_value WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type;
                 END IF;
                 END IF;
                 SET daily_value = 0;
                 IF EXISTS(SELECT id FROM daily_statistics WHERE keyword_id = new.keyword_id AND start_day = r_time AND statistics_type_id = s2_type LIMIT 1) THEN
                    SELECT d.value INTO daily_value FROM daily_statistics d WHERE keyword_id = new.keyword_id AND start_day = r_time AND statistics_type_id = s2_type;
                    SET daily_value = daily_value - 1;
                    UPDATE daily_statistics d SET d.value = daily_value WHERE keyword_id = new.keyword_id AND start_day = r_time AND statistics_type_id = s2_type;
                 END IF;
              END IF;
        ELSE
              SELECT keyword_type INTO old_keyword_type FROM keywords WHERE id = old.keyword_id;
              SELECT keyword_type INTO new_keyword_type FROM keywords WHERE id = new.keyword_id;
              IF (old_keyword_type <> new_keyword_type) OR (new.keyword_id <> old.keyword_id) THEN
                 IF (SELECT default_value FROM configurations WHERE variable = 'activeId' LIMIT 1) = '1' THEN
                     IF EXISTS(SELECT id FROM voice_logs_1 WHERE id = new.voice_log_id) THEN
                     SELECT agent_id,start_time INTO agent,s_time FROM voice_logs_1 WHERE id = new.voice_log_id;
                     SET r_time =  CAST(s_time AS DATE);
                     END IF;
                 ELSE
                     IF EXISTS(SELECT id FROM voice_logs_2 WHERE id = new.voice_log_id) THEN
                     SELECT agent_id,start_time INTO agent,s_time FROM voice_logs_2 WHERE id = new.voice_log_id;
                     SET r_time =  CAST(s_time AS DATE);
                     END IF;
                 END IF;
              -- decrease old keyword value and statistic
              CASE old_keyword_type
              WHEN 'n' THEN
                          BEGIN
                          SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:n';
		          IF EXISTS(SELECT id FROM voice_log_counters WHERE voice_log_id = new.voice_log_id) THEN
                             SELECT keyword_count,ngword_count INTO total_keyword,total_ng
                             FROM voice_log_counters WHERE voice_log_id = new.voice_log_id;
                             SET total_keyword = total_keyword - 1;
                             SET total_ng = total_ng - 1;
                             UPDATE voice_log_counters SET keyword_count = total_keyword,ngword_count = total_ng WHERE voice_log_id = new.voice_log_id;
                          END IF;
                          END;
                 WHEN 'm' THEN
                          BEGIN
                          SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:m';
		          IF EXISTS(SELECT id FROM voice_log_counters WHERE voice_log_id = new.voice_log_id) THEN
                             SELECT keyword_count,mustword_count INTO total_keyword,total_must
                             FROM voice_log_counters WHERE voice_log_id = new.voice_log_id;
                             SET total_keyword = total_keyword - 1;
                             SET total_must = total_must - 1;
                             UPDATE voice_log_counters SET keyword_count = total_keyword,mustword_count = total_must WHERE voice_log_id = new.voice_log_id;
                             END IF;
                          END;
                 WHEN 'a' THEN SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:a';
                 END CASE;
                 SET daily_value = 0;
                 IF agent IS NOT NULL AND agent > 0 AND r_time IS NOT NULL THEN
                 IF EXISTS(SELECT id FROM daily_statistics WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type) THEN
                    SELECT d.value INTO daily_value FROM daily_statistics d WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type;
                    SET daily_value = daily_value - 1;
                    UPDATE daily_statistics d SET d.value = daily_value WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type;
                 END IF;
                 END IF;
                 SET daily_value = 0;
                 IF EXISTS(SELECT id FROM daily_statistics WHERE keyword_id = old.keyword_id AND start_day = r_time AND statistics_type_id = s2_type LIMIT 1) THEN
                    SELECT d.value INTO daily_value FROM daily_statistics d WHERE keyword_id = old.keyword_id AND start_day = r_time AND statistics_type_id = s2_type;
                    SET daily_value = daily_value - 1;
                    UPDATE daily_statistics d SET d.value = daily_value WHERE keyword_id = old.keyword_id AND start_day = r_time AND statistics_type_id = s2_type;
                 END IF;
                 -- decrease old keyword value and statistic
                 -- increase new keyword value and statistic
                 CASE new_keyword_type
              WHEN 'n' THEN
                          BEGIN
                          SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:n';
		          IF EXISTS(SELECT id FROM voice_log_counters WHERE voice_log_id = new.voice_log_id) THEN
                             SELECT keyword_count,ngword_count INTO total_keyword,total_ng
                             FROM voice_log_counters WHERE voice_log_id = new.voice_log_id;
                             SET total_keyword = total_keyword + 1;
                             SET total_ng = total_ng + 1;
                             UPDATE voice_log_counters SET keyword_count = total_keyword,ngword_count = total_ng WHERE voice_log_id = new.voice_log_id;
                          END IF;
                          END;
                 WHEN 'm' THEN
                          BEGIN
                          SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:m';
		          IF EXISTS(SELECT id FROM voice_log_counters WHERE voice_log_id = new.voice_log_id) THEN
                             SELECT keyword_count,mustword_count INTO total_keyword,total_must
                             FROM voice_log_counters WHERE voice_log_id = new.voice_log_id;
                             SET total_keyword = total_keyword + 1;
                             SET total_must = total_must + 1;
                             UPDATE voice_log_counters SET keyword_count = total_keyword,mustword_count = total_must WHERE voice_log_id = new.voice_log_id;
                             END IF;
                          END;
                 WHEN 'a' THEN SELECT id INTO s_type FROM statistics_types WHERE target_model = 'ResultKeyword' AND value_type = 'sum:a';
                 END CASE;
                 SET daily_value = 0;
                 IF agent IS NOT NULL AND agent > 0 AND r_time IS NOT NULL THEN
                 IF EXISTS(SELECT id FROM daily_statistics WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type) THEN
                    SELECT d.value INTO daily_value FROM daily_statistics d WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type;
                    SET daily_value = daily_value + 1;
                    UPDATE daily_statistics d SET d.value = daily_value WHERE agent_id = agent AND start_day = r_time AND statistics_type_id = s_type;
                 END IF;
                 END IF;
                 SET daily_value = 0;
                 IF EXISTS(SELECT id FROM daily_statistics WHERE keyword_id = new.keyword_id AND start_day = r_time AND statistics_type_id = s2_type LIMIT 1) THEN
                    SELECT d.value INTO daily_value FROM daily_statistics d WHERE keyword_id = new.keyword_id AND start_day = r_time AND statistics_type_id = s2_type;
                    SET daily_value = daily_value + 1;
                    UPDATE daily_statistics d SET d.value = daily_value WHERE keyword_id = new.keyword_id AND start_day = r_time AND statistics_type_id = s2_type;
                 END IF;
              END IF;
              -- increase new keyword value and statistic
        END IF;
    END;
SQL

  end

  def self.down
    execute "DROP TRIGGER IF EXISTS modify_statistics_when_edit_change"
  end
end
