module StatsData
  class MySQLTableInfo < StatsBase
    
    def self.run
      tbi = new
      tbi.update
    end
    
    def update
      result = ActiveRecord::Base.connection.select_all(sql_string)
      unless result.empty?
        clear_info
        result.each do |rs|
          rc  = record_info(rs)
          tif = TableInfo.new(rc)
          tif.save!
        end
        result = []
      end
      logger.info "updated table informations"
    end
  
    private
    
    def sql_string
      sql = %{SELECT *
              FROM information_schema.TABLES
              WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = '#{Settings.server.database.dbname}'
            }
      return sql.gsub(/\s+/," ")
    end
    
    def record_info(rs)
      return {
        db_name:      rs['TABLE_SCHEMA'],
        tbl_name:     rs['TABLE_NAME'],
        engine_name:  rs['ENGINE'],
        rows_count:   rs['TABLE_ROWS'],
        data_length:  rs['DATA_LENGTH'],
        index_length: rs['INDEX_LENGTH'],
        data_free:    rs['DATA_FREE']
      }
    end
    
    def clear_info
      TableInfo.delete_all
    end
    
  end
end