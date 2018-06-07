require "bunny"
require "json"

module AnalyticTrigger
  
  #
  # class to used for check and forward message to AOHS api
  # - desktop notification message
  # - keyword notification
  # - recommendation alert
  #
  
  class NotificationReceiver
     
    def self.run
      nrf = new
      nrf.run
    end
    
    def initialize
      AnalyticTrigger.logger.info "Starting notification receiver."
      connect
    end
    
    def run
      if connected?
        r_ch = @conn.create_channel
        r_q = r_ch.queue(Settings.server.rabbitmq.queue_notify, durable: true)
        begin
          # loop for waiting to receive message
          AnalyticTrigger.logger.info "waiting message from queue #{Settings.server.rabbitmq.queue_notify}."
          r_q.subscribe(:block => true) do |delivery_info, properties, body|
            send_message_data(parse_message(body))
          end
        rescue
          disconnect
        end
      end
    end
    
    private
    
    def parse_message(message_string)
      output = message_string
      begin
        output = JSON.parse(message_string)
        log :info, "received message: #{message_string}"
        if output.is_a?(Array)
          # first message only
          output = output.first
        end
        @current_id = output["id"]
        output["received_message_at"] = Time.now
      rescue => e
        log :error, "invalid message format, #{e.message}"
        output = {}
      end
      return output
    end
    
    def send_message_data(message)
      params = message_params(message)
      unless params.nil?
        begin
          log :info, "message: #{params.inspect}"
          headers = {
            content_type: :json,
            accept: :json
          }
          
          response = RestClient::Request.execute(method: :post, url: process_url, timeout: 10, payload: params.to_json, headers: headers)
          response_rs = JSON.parse(response.body)
          
          log :info, "result: #{response_rs.inspect}"
          begin
            if message.has_key?("process_time")
              log :info, "ana.engine ps-time: #{message["process_time"].to_f.round(6)}"
            end
          rescue
          end
          log :info, "sending ps-time: #{diff_msec(response_rs["sent_at"],params["received_message_at"])}"
        rescue => e
          log :error, "sending message error, #{e.message}"
        end
      end
    end
    
    def process_url
      url = Settings.server.analytic.notification_url + "?do_act=send"
      return url
    end
    
    def message_params(message)
      # prepare data which is received from message queue
      # do mapping fields, validate fields, and initial data
      
      p = {}
      m = message
      found_content = false
            
      #
      # check target user
      #
      
      p_agent_name = m["agent_name"].to_s
      p_agent_id = m["agent_id"].to_s
      if p_agent_name.length <=0 and p_agent_id.length <= 0
        log :error, "username or id is blank"
        return nil
      else
        p["agent_name"] = p_agent_name if p_agent_name.length > 0
        p["agent_id"] = p_agent_id if p_agent_id.length > 0
      end
      
      #
      # prepare keyword alert content
      # auto check and reformat parameters structure
      #
      
      unless m["detected_keywords"].nil?
        unless m["detected_keywords"].empty?
          m["detected_keyword"] = m["detected_keywords"].first
          begin
            if m["start_msec"].nil?
              m["start_msec"] = m["detected_keyword"]["start_msec"]
            end
          rescue
          end
        else
          if not m["keyword_id"].nil? 
            m["detected_keyword"] = {
              "keyword_id" => m["keyword_id"],
              "keyword_name" => m["detected_keyword"],
              "start_msec" => m["start_msec"],
              "end_msec" => m["end_msec"]
            }
          end
        end
      else
        if m["content_type"] == "keyword" and not m["keyword_id"].nil?
          m["detected_keyword"] = {
            "keyword_id" => m["keyword_id"],
            "keyword_name" => m["detected_keyword"],
            "start_msec" => m["start_msec"],
            "end_msec" => m["end_msec"]
          }
        end
      end
      unless m["detected_keyword"].blank?
        dkeyword = Keyword.create_message(m["detected_keyword"])
        unless dkeyword.nil?
          p["content_type"] = "keyword"
          p["detected_keyword"] = dkeyword
          p["detected_sentence"] = m["text"]
          p["start_msec"] = m["start_msec"]
          p["end_msec"] = m["end_msec"]
          p["channel"] = m["channel"]
          p["speaker_type"] = m["speaker_type"]
          unless m["timestamp"].nil?
            p["detected_rs_at"] = m["timestamp"]
          else
            unless m["analytic_timestamp"].nil?
              p["detected_rs_at"] = m["analytic_timestamp"]
            end
          end
          found_content = true
        else
          log :warn, "keyword is not defined or disabled"
          return nil
        end
      end
      
      #
      # prepare faq and recommendation content
      #
      
      if m["content_type"].to_s.downcase == "faq"
        p["content_type"] = m["content_type"].to_s.downcase
        p["faq_id"] = m["question_id"]
        p["faq_pattern_id"] = m["faq_question_pattern_id"]
        p["faq_answers_id"] = m["faq_answer_ids"]
        p["detected_sentence"] = m["detected_text"]
        p["detected_rs_at"] = m["analytic_timestamp"]
        p["start_msec"] = m["start_msec"]
        p["end_msec"] = m["end_msec"]
        p["channel"] = m["channel"]
        p["dsr_ut_ended_at"] = m["dsr_ut_ended_at"]
        p["dsr_rs_created_at"] = m["dsr_rs_created_at"]
        p["dsr_rs_accepted_at"] = m["dsr_rs_accepted_at"]
        if p["faq_answers_id"].nil? or p["faq_answers_id"].empty?
          # no return answers - rejected
        else
          found_content = true
        end
      end

      unless found_content
        log :warn, "mismatch content type or invalid message format."
        return nil
      end
      
      # other parameters
      p["received_message_at"] = m["received_message_at"]
      p["received_rs_at"] = m["received_message_at"]
      p["call_id"] = m["call_id"] unless m["call_id"].blank?
      p["voice_log_id"] = m["id"] unless m["id"].blank?
      
      return p
    end
    
    def connect
      @connected = false
      @stoping = true
      begin
        xhost = Settings.server.rabbitmq.host
        xport = Settings.server.rabbitmq.port
        xvhost = Settings.server.rabbitmq.vhost
        xuser = Settings.server.rabbitmq.username
        xpass = Settings.server.rabbitmq.password
        @conn = Bunny.new(:hostname => xhost, :vhost => xvhost, :port => xport, :username => xuser, :password => xpass)
        @conn.start
        @connected = true
        @stoping = false
      rescue => e
        log :error, "error to create connection to rbmq - #{e.message}"
      end
    end
    
    def disconnect
      begin
        @conn.close
      rescue => e
        log :error, "error while closing connection from rbmq - #{e.message}"
      end
      @connected = false
    end
    
    def connected?
      @connected
    end
    
    def stop?
      @stoping
    end

    def diff_msec(t1,t2=Time.now)
      if t1.is_a?(String)
        t1 = Time.parse(t1)
      end
      if t2.is_a?(String)
        t2 = Time.parse(t2)
      end
      return (t1.to_f - t2.to_f).round(5)
    end
    
    def log(type, msg)
      vid = @current_id.to_s
      vid = " - #{vid}" unless vid.blank?
      case type
      when :error
        AnalyticTrigger.logger.error "(notify)#{vid} - #{msg}"
      when :warn
        AnalyticTrigger.logger.warn  "(notify)#{vid} - #{msg}"
      else
        AnalyticTrigger.logger.info  "(notify)#{vid} - #{msg}"
      end
    end
    
  end
end