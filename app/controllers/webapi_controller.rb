class WebapiController < ApplicationController
  
  protect_from_forgery except: [:update_computer_logs, :update_computer_log, :agent_activity, :client_notify]
  
  def index
    render layout: false
  end
  
  #
  # resources 
  #
  
  def users
    sql = []
    sql << "SELECT u.id AS user_id, r.name AS role_name, r.priority_no AS role_priority,"
    sql << "s0.delinquent AS delinquent2,"
    sql << "a100.attr_val AS delinquent1"
    sql << "FROM users u"
    sql << "LEFT JOIN roles r ON u.role_id = r.id"
    sql << "LEFT JOIN (SELECT t.user_id, GROUP_CONCAT(t.delinquent_no) AS delinquent FROM user_atl_attrs t WHERE flag <> 'D' GROUP BY t.user_id) s0 ON s0.user_id = u.id"
    sql << "LEFT JOIN user_attributes a100 ON u.id = a100.user_id AND a100.attr_type = 100"
    sql << "WHERE u.state <> 'D'"
    sql << "ORDER BY u.id"
    
    respond_to do |format|
      format.json {
        result = ActiveRecord::Base.connection.select_all(sql.join(" "))
        result = result.to_a.map { |r| 
          {
            user_id: r["user_id"],
            role_name: r["role_name"],
            role_priority: r["role_priority"],
            delinquent: ("#{r["delinquent2"]},#{r["delinquent1"]}".split(",").uniq.select { |q| !q.blank? }).join(",")
          }
        }
        render json: result        
      }
    end
  end
  
  # this url will be called by AmiWatcher
  # to logging client computer information
  
  def update_computer_logs
    update_computer_log
  end
  
  def update_computer_log

    messages = []
    data = {}
    
    cl = ComputerLog.new
    cl.check_time = Time.zone.now
    cl.remote_ip = get_real_remote_ip
    
    if got_param?(:computer_name)
      cl.computer_name = params[:computer_name].strip
    end
    
    if got_param?(:login_name)
      cl.login_name = params[:login_name].strip
    end
    
    if got_param?(:remote_ip)
      cl.remote_ip = params[:remote_ip].strip
    end
    
    if got_param?(:event)
      cl.computer_event = params[:event]
    end
    
    params.each_pair do |k,v|
      kname = k.to_s
      v = v.to_s.strip
      next if ['controller','action','id'].include?(kname)
      case kname
      when /^computer_name$/
        data[:computer_name] = v
      when /^login_name$/
        data[:login_name] = v          
      when /^watcher/
        data[:watcher_version] = v
        cl.watcher_version = v
      when /^advw/,/^audioviewer/
        data[:audioviewer_version] = v
        cl.audioviewer_version = v
      when /^cti/
        data[:cti_version] = v
        cl.cti_version = v
      when /^os/
        data[:os_version] = v
        cl.os_version = v
      when /^java/
        data[:java_version] = v
        cl.java_version = v
      when /(.+)_version$/
        data[:other_vers] = "" if data[:other_vers].nil?
        data[:other_vers].concat("#{kname}=#{v},")
      when /^(event)/
        data[:computer_event] = v
      else
        messages << "unknown parameter #{kname}"
      end
    end
    
    if not cl.remote_ip.blank? and not cl.login_name.blank?
      if cl.save
        messages << "OK"
      end
    else
      messages << "missing required paramters."
    end

    result_msg = update_extension_mapping(cl, data)
    unless result_msg.blank?
      messages << result_msg
    end
    
    html = []
    html << "- computer log"
    html << "computer_ip=#{params[:remote_ip]}"
    html << "computer_name=#{cl.computer_name}"
    html << "windows_logon=#{cl.login_name}"
    html << "updated_at=#{Time.zone.now.to_formatted_s(:web)}"
    html << "message=#{messages.join(',')}"
    
    Rails.logger.info "ComputerLog Result: #{html.join(" ")}"
    
    render text: html.join("<br/>"), layout: false
  end
  
  def agent_lookup
    numbers = params[:number].to_s.split(",")
    @rets = [0,0]
    unless numbers.empty?
      begin
        numbers.each do |number|
          number = number.strip
          sql_where = "extension LIKE '#{number}' OR did LIKE '#{number}'"        
          sql = "SELECT * FROM current_extension_agent_maps WHERE #{sql_where} ORDER BY priority_no LIMIT 1"
          result = ActiveRecord::Base.connection.select_all(sql)
          unless result.empty?
            result = result.first
            @rets = [result["agent_id"], result["extension"]]  
          end
        end
      rescue => e
        Rails.logger.error "Error AgentLookup - #{e.message}"
      end
    end
    render text: @rets.first #@rets.join(",")
  end
  
  def agent_activity
    flag_act = false
    flag_idle = false
    x_newline = "\n"
    x_tab = "\t"
    
    if Settings.watcher.agentactivity.enable
      begin
        result = params["result"]
      rescue => e
        result = params["result"]
      end
      
      mapped_result = {
        login: nil,
        user_id: 0,
        remote_ip: get_real_remote_ip,
        mac: nil,
        activities: [],
        idles: []
      }
  
      result.to_s.split(x_newline).each do |line|
        line = line.chomp
        next if line.empty?
        case line
        when /^#LoginName/
          mapped_result[:login] = line.gsub("#LoginName=","")
          user = User.select(:id).where({login: mapped_result[:login]}).first
          unless user.nil?
            mapped_result[:user_id] = user.id
          end
        when /^#MacAddress/
          mapped_result[:mac] = line.gsub("#MacAddress=","")
        when /^__AGENT_ACTIVITY__/
          flag_act = true
          flag_idle = false
        when /^__IDLE_TIME__/
          flag_act = false
          flag_idle = true
        when /^__BROWSER_HISTORY__/
          # nothing
        when /^__WATCHER__/
          # nothing
        when /\d{4}-\d{2}-\d{2} \d{2}:\d{2}/
          case true
          when flag_act
            mapped_result[:activities] << line.split(x_tab)
          when flag_idle
            mapped_result[:idles] << line.split(x_tab)
          end
        else
          Rails.logger.debug "Activity log does not match - #{line}"
        end
      end
      
      UserActivityLog.update_logs_from_watcher(mapped_result)
      UserActivityLog.update_idle_logs_from_watcher(mapped_result)
    end
    
    render text: 'true' 
  end
  
  def checker
    render text: "AOHS - " + Time.now.to_formatted_s(:web)
  end
  
  def assessment_rules
    rules = AnalyticUtils::AssessmentRuleBase.rules_data
    rules.each do |rule|
      ar = ElsClient::AssessmentRule.new(rule[:question_id])
      if ar.exists?
        ar.delete
      end
      rule["_id"] = rule[:question_id]
      #ar = ElsClient::AssessmentRule.new(rule)
      #ar.create
      break
    end
    
    render json: rules.to_json
  end
  
  def faq_questions
    fpath = FaqQuestion.create_source_file
    send_data File.read(fpath), type: "text/json", filename: "faq.json"
  end
  
  def dictionary
    fields = [:word, :spoken_word, :class_map, :updated_at]
    dict = CustomDictionary.select(fields).order(:word).all
    respond_to do |format|
      format.json {
        render json: dict.to_json(only: fields)
      }
    end
  end

  def client_notify
    
    #
    # notification APIs
    # - register and get configuration
    # - post/send message
    #
    
    ret = {
      success: false
    }
    
    act = params[:do_act].to_s.downcase.to_sym
    
    case act
    when :register
      login = params[:login_name]
      remote_ip = get_real_remote_ip
      user = User.where(login: login).first
      unless user.nil?
        ret[:success] = true
        ret[:login_name] = user.login
        ret[:queue_name] = "amiwatcher.#{user.login}"
        ret[:timestamp] = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        ret[:rabbitmq] = {
          host: Settings.server.rabbitmq.host,
          port: Settings.server.rabbitmq.port,
          vhost: Settings.server.rabbitmq.vhost,
          username: Settings.server.rabbitmq.username,
          password: Settings.server.rabbitmq.password,
          connection_timeout: 1.5,
          wait_connection_timeout: 5
        }
      end
    
    when :send
      cli_notif = ClientNotify.parse(params)
      ret[:success], ret[:message] = cli_notif.send
      ret[:sent_at] = cli_notif.send_out_at.strftime("%Y-%m-%d %H:%M:%S.%3N") 
    else
      ret[:message] = "invalid action #{act}"
    end
    
    render json: ret
  end
  
  private
  
  def got_param?(key)
    return (params.has_key?(key) and not params[key].empty?)
  end
  
  def update_extension_mapping(cl, data={})
    messages = []
    user = get_user_from_login(cl.login_name)
    unless user.nil?
      comps = ComputerInfo.select(:extension_id).where(["ip_address = ? OR computer_name = ?",cl.remote_ip,cl.computer_name]).order(id: :desc).all
      unless comps.empty?
        # find numbers
        ext = Extension.where(id: comps.map { |c| c.extension_id }).order(id: :desc).first
        dids = Did.where(extension_id: comps.map { |c| c.extension_id }).all        
        if computer_logoff?(data[:computer_event])
          # remove mapped number
          mapped_numbers = []
          uems = UserExtensionMap.where("agent_id = #{user.id}").all
          uems.each { |x|
            mapped_numbers << x.extension
            mapped_numbers << x.did
            x.delete
          }
          messages << "unmapped numbers=#{mapped_numbers.uniq.join("|")}"
        else
          # update mapped number
          # find and remove mapped numbers
          wheres = []
          unless ext.nil?
            wheres << "extension = '#{ext.number}'"
          end
          unless dids.empty?
            wheres << "did IN (#{(dids.map { |d| "'#{d.number}'" }).join(",")})"
          end
          uems = UserExtensionMap.where("agent_id = #{user.id} AND (#{wheres.join(" OR ")})")
          uems.each { |x| x.delete }
          # add new numbers
          mapped_numbers = []
          ds = {
            extension: ext.number, did: nil,
            agent_id: user.id
          }
          if dids.empty?
            uem = UserExtensionMap.new(ds)
            if uem.save
              mapped_numbers << uem.extension
            end
          else
            dids.each do |did|
              ds[:did] = did.number
              uem = UserExtensionMap.new(ds)
              if uem.save
                mapped_numbers << uem.extension
                mapped_numbers << uem.did
              end
            end
          end
          messages << "mapped numbers=#{mapped_numbers.uniq.join("|")}"
        end
      else
        messages << "no computer"
      end
    else
      messages << "no username #{cl.login_name}"
    end
    return messages.join(",")
  end
  
  def computer_logoff?(event_name)
    return event_name == "logoff"  
  end
  
  def get_user_from_login(login_name)
    user = User.not_deleted.select(:id).where(login: login_name).first
    if user.nil?
      # auto create user if not found in the system
      # TODO
    end
    return user
  end
  
  def get_real_remote_ip
    client_ip = request.env["HTTP_X_FORWARDED_FOR"].to_s
    if client_ip.empty?
      client_ip = request.env['REMOTE_ADDR'].to_s
      if client_ip.empty?
        client_ip = request.remote_ip
      end
    end
    return client_ip
  end
  
  # end class
end
