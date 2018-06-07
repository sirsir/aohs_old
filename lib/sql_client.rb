class SqlClient
  # active-record api shortcut
  
  def self.select(sql)
    return ActiveRecord::Base.connection.select_all(sql)
  end
  
end