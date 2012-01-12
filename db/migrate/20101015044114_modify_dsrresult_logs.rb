class ModifyDsrresultLogs < ActiveRecord::Migration
  def self.up
        execute "ALTER TABLE dsrresult_logs MODIFY COLUMN id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
                 MODIFY COLUMN voice_log_id BIGINT(20) UNSIGNED DEFAULT NULL,
                 MODIFY COLUMN agent_id BIGINT(20) UNSIGNED DEFAULT NULL,
                 MODIFY COLUMN server_name VARCHAR(21)  CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL;"
  end

  def self.down
  end
end

