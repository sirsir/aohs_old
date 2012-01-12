class QueryController < ApplicationController

	require 'cgi'
	
	def query
	
		result = ""
		format = "text"
        
		if params.has_key?(:query) and not params[:query].empty?
			
			sql = params[:query]
			sql = CGI::unescape(sql)

            begin
              case sql
                when /^select/
					data = ActiveRecord::Base.connection.select_all(sql)    # return result set
					tmp = []
					unless data.empty?
						data.each do |o|
							if tmp.empty?
								tmp << (o.keys).join("\t")
							end
							tmp << (o.values).join("\t")
						end
					end
					data = tmp.join("\n")
                when /^insert/
                  data = ActiveRecord::Base.connection.insert(sql)        # return insert id
                when /^update/
                  data = ActiveRecord::Base.connection.update(sql)        # return number of row to updated
                when /^delete/
                  data = ActiveRecord::Base.connection.delete(sql)        # return number of row to deleted
                else
                  data = ActiveRecord::Base.connection.execute(sql)
              end
              result = data
            rescue => e
              result = "query=#{sql}<br>message=#{e.message}"
            end
        else
          result = "No query statement"
		end

		send_data(result)
      
	end
	
end
