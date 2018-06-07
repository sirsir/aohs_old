module AnalyticTrigger
  class AnaTaskResult
    
    def self.get_result(options)
      return new(options)
    end
    
    def initialize(options)
      @options = init_options(options)
      @data = nil
      @messages = []
      get_data_from_url
    end
    
    def raw_result
      return @data
    end
    
    def messages
      return @messages
    end
    
    private
    
    def get_data_from_url
      begin
        headers = {
          content_type: :json, accept: :json
        }
        @messages << "parameters: #{@options[:params].to_json}"
        response = RestClient::Request.execute(method: @options[:method], url: @options[:url], timeout: @options[:timeout], payload: @options[:params].to_json, headers: headers)
        @data = parse_result(JSON.parse(response.body))
        @messages << "received result: #{@data.to_json}"
      rescue => e
        @messages << "error while waiting result from url #{@options[:url]}, #{e.message}"
      end
    end
    
    def parse_result(data)
      return data
    end
    
    def init_options(options)
      options[:method] = options[:method] || :post
      options[:timeout] = options[:timeout] || 60
      return options
    end
    
  end
end