require 'securerandom'

class ClientNotify

  def self.parse(params)
    new(params)
  end
  
  def initialize(params)
    @message_params = params
    @errors = []
    @send_out_at = Time.now
  end
  
  def send
    if valid_message?
      
      # create notification template
      template = NotificationTemplate.new(@message)
      data = template.render
      
      # prepare message data
      mq_params = create_output_params(data)

      # send message
      mq_result = RabbitmqClient.send(mq_params)
      @send_out_at = Time.now
      unless mq_result.success
        @errors.concat(mq_result.error_messages)
      end
      
      # send copy message (cc)
      unless data[:cc_content].nil?
        cc_users = get_cc_users
        unless cc_users.empty?
          mq_params_cc = create_output_params_cc(data, mq_params)
          cc_users.each do |cc_user|
            mq_params_cc[:target_queue] = get_queue_name(cc_user)
            cc_result = RabbitmqClient.send(mq_params_cc)
            @errors.concat(cc_result.error_messages)
          end
        end
      end
      
      # send copy (mirror)
      begin
        mi_users = Settings.watcher.notification.mirror_client.to_s.split(",")
        unless mi_users.empty?
          mq_params_mi = create_output_params(data)
          mi_users.each do |mi_user|
            mq_params_mi[:target_queue] = get_queue_name(mi_user)
            mi_result = RabbitmqClient.send(mq_params_mi)
            @errors.concat(mi_result.error_messages)
          end
        end
      rescue => e
      end
      
      # keep log
      keep_message_log(data, mq_result)
    end
    
    print_error_result
    return !errors?, @errors  
  end
  
  def errors?
    return (not @errors.empty?)
  end
  
  def send_out_at
    return @send_out_at  
  end
  
  private
  
  def valid_message?
    return init_message_data
  end
  
  def create_output_params(data)
    return {
      target_queue: @message[:target_queue],
      timeout: data[:timeout],
      height: data[:dialog_height],
      width: data[:dialog_width],
      play_sound: data[:play_sound_alert],
      level: data[:level],
      title: data[:title],
      subject: data[:subject],
      content_type: data[:content_type],
      content: data[:notify_content],
      content_details: data[:content],
      timestamp: data[:timestamp],
      message_uuid: @message[:message_id]
    }
  end
  
  def create_output_params_cc(data, m_params)
    cc_params = m_params.clone
    cc_params[:title] = data[:cc_title]
    cc_params[:content_details] = data[:cc_content]
    return cc_params
  end
  
  def init_message_data
    @message = {}
    @message = @message_params
    
    # message timestamp
    if @message[:timestamp].blank?
      @message[:timestamp] = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end
    
    # message uuid
    @message[:message_id] = Time.now.strftime("%y%m") + "-" + SecureRandom.urlsafe_base64(8)
    
    # target user / queue name
    targ_user = get_target_user
    unless targ_user.nil?
      @message[:target_queue] = get_queue_name(targ_user.login)
      @message[:who_receive_id] = targ_user.id
      @message[:agent_display_name] = targ_user.display_name
    end
    
    log "Notification params - #{@message.to_json}"
    return !errors?
  end
  
  def get_target_user
    target_user = nil
    
    if @message_params.has_key?(:agent_name) and not @message_params[:agent_name].empty?
      target_user = User.select_only(:names).where(login: @message_params[:agent_name]).first
    end
    
    if target_user.nil? and @message_params.has_key?(:agent_id) and not @message_params[:agent_id].empty?
      target_user = User.select_only(:names).where(id: @message_params[:agent_id]).first
    end
    
    if target_user.nil? and @message_params.has_key?(:user) and not @message_params[:user].empty?
      target_user = User.select_only(:names).where(login: @message_params[:user]).first
    end
    
    if target_user.nil?
      ulist = []
      ulist << @message_params[:agent_name]
      ulist << @message_params[:agent_id]
      ulist << @message_params[:user]
      @errors << "no user in the system, [#{ulist.join(",")}]"
      target_user = nil
    end
    
    return target_user
  end
  
  def get_cc_users
    cc_users = []
    group = User.get_group_info(@message[:who_receive_id])
    unless group.nil?
      leader = group.leader_info(GroupMemberType::T_LEADER)
      unless leader.nil?
        if leader.user_id.to_i > 0
          cc_users << User.select(:login).where(id: leader.user_id).first.login
        end
      end
    end
    return cc_users
  end
  
  def get_queue_name(target_name)
    queue_prefix = Settings.server.rabbitmq.queue_amiwatcher
    return [queue_prefix, target_name].join(".")
  end

  def keep_message_log(data, mq_result)
    ref_id = 0
    if not data[:keyword_id].blank?
      ref_id = data[:keyword_id]
    elsif not data[:faq_id].blank?
      ref_id = data[:faq_id]
    end
    mlog = {
      message_type: data[:message_type],
      who_sent: 0,
      who_receive: @message[:who_receive_id].to_i,
      reference_id: ref_id,
      read_flag: "",
      useful_flag: "",
      voice_log_id: @message[:voice_log_id].to_i,
      message_uuid: @message[:message_id],
      start_msec: @message[:start_msec],
      end_msec: @message[:end_msec],
      dsr_ut_ended_at: @message[:dsr_ut_ended_at],
      dsr_rs_created_at: @message[:dsr_rs_created_at],
      dsr_rs_accepted_at: @message[:dsr_rs_accepted_at],
      created_at: mq_result.sent_at
    }
    @message["sent_msg_at"] = mq_result.sent_at
    mlog = MessageLog.create(mlog)
    mlog.store_message_detail(@message)
  end
  
  def print_error_result
    unless @errors.empty?
      log "error - #{@errors.join(",")}"
    end
  end
  
  def log(msg)
    Rails.logger.info "(client-notify) - #{msg}"
  end

end