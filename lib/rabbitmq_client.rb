require "bunny"

class RabbitmqClient
  
  # object return result
  SendMessageResult = Struct.new(:message, :success, :error_messages, :sent_at)

  # mq connection
  @@rbmq_conn = nil

  def self.send(params)
    @errors = []
    
    tnow = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    if connected?
      begin
        ch = @@rbmq_conn.create_channel
        q = ch.queue(params[:target_queue], :durable => true)
        ch.default_exchange.publish(params.to_json, :routing_key => q.name, :auto_delete => true)
        disconnect
        log "message has been sent to #{params[:target_queue]}, #{params[:message_uuid]}"
      rescue => e
        disconnect
        @errors << e.message
        log "error sending message to #{params[:target_queue]}, #{params[:message_uuid]}, #{e.message}"
      end
    end
    
    return SendMessageResult.new(params, @errors.empty?, @errors, tnow)
  end
  
  private
  
  def self.connected?
    begin
      if @@rbmq_conn.nil?
        xhost = Settings.server.rabbitmq.host
        xport = Settings.server.rabbitmq.port
        xvhost = Settings.server.rabbitmq.vhost
        xuser = Settings.server.rabbitmq.username
        xpass = Settings.server.rabbitmq.password
        @@rbmq_conn = Bunny.new(:hostname => xhost, :vhost => xvhost, :port => xport, :username => xuser, :password => xpass)
        @@rbmq_conn.start
      end
    rescue => e
      disconnect
      @errors << e.message
      return false
    end
    return true
  end
  
  def self.disconnect
    begin
      @@rbmq_conn.close
    rescue => e
    end
    @@rbmq_conn = nil
  end
  
  def self.log(msg)
    Rails.logger.info "(rabbitmq-client) - #{msg}"  
  end
  
  # end class
end