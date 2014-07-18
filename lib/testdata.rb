#!/usr/bin/ruby
# helper methods
class String
   def db_quot(q='"')
      "#{q}" + self + "#{q}"
   end
end
class Fixnum
   def db_quot(q='"')
      self.to_s
   end
end
class Time
   def db_quot (q='"')
      "#{q}" + self.strftime('%Y/%m/%d %H:%M:%S') + "#{q}"
   end
end
def insert_sql(table_name, values)
   "insert into #{table_name} values(#{values.map{ |x| x.db_quot }.join(',')});"
end
