module AnalyticTrigger
  class SqlClient
    
    def self.select_all(sql)
      return ActiveRecord::Base.connection.select_all(sql)
    end
    
    def self.delete(sql)
      ActiveRecord::Base.connection.execute(sql)
    end
    
    # end class
  end
end