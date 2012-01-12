class ChangeIdType < ActiveRecord::Migration
  def self.up

    execute "ALTER TABLE customers MODIFY COLUMN `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE customer_numbers MODIFY COLUMN `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT;"
    
    execute "ALTER TABLE call_bookmarks MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE call_informations MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE voice_logs MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE result_keywords MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE voice_log_counters MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE voice_log_customers MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE edit_keywords MODIFY COLUMN `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT;"

    execute "ALTER TABLE call_bookmarks MODIFY COLUMN `voice_log_id` BIGINT UNSIGNED NOT NULL;"
    execute "ALTER TABLE call_informations MODIFY COLUMN `voice_log_id` BIGINT UNSIGNED NOT NULL;"
    execute "ALTER TABLE call_bookmarks MODIFY COLUMN `voice_log_id` BIGINT UNSIGNED NOT NULL;"
    execute "ALTER TABLE result_keywords MODIFY COLUMN `voice_log_id` BIGINT UNSIGNED NOT NULL;"
    execute "ALTER TABLE taggings MODIFY COLUMN `taggable_id` BIGINT UNSIGNED NOT NULL;"
    execute "ALTER TABLE voice_log_counters MODIFY COLUMN `voice_log_id` BIGINT UNSIGNED NOT NULL;"
    execute "ALTER TABLE voice_log_customers MODIFY COLUMN `voice_log_id` BIGINT UNSIGNED NOT NULL;"
    
  end

  def self.down
    
  end
  
end
