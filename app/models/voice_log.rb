class VoiceLog < ActiveRecord::Base
  
  IINDEX_STIME = 'index_stime'
  TempFileDs = Struct.new(:path, :url)
  
  belongs_to    :user,          foreign_key: :agent_id
  has_one       :group_member,  through: :user
  has_one       :group,         through: :group_member
  has_many      :taggings,      foreign_key: :tagged_id
  has_many      :voice_logs
  has_many      :call_comments
  has_many      :call_informations
  has_many      :call_transcriptions
  has_many      :call_classifications
  has_one       :call_customer
  has_one       :customer,     through: :call_customer
  has_many      :result_keywords
  has_many      :dsrresult_logs
  has_many      :call_favourites
  has_many      :evaluation_calls

  alias_attribute :voice_log_id, :id
  
  scope :start_time_bet, -> (fr,to){
    if fr.is_a?(String)
      fr = Time.parse(fr)
    end
    if to.is_a?(String)
      to = Time.parse(to)
    end  
    where("start_time BETWEEN ? AND ?",fr.to_formatted_s(:db),to.to_formatted_s(:db))
  }

  scope :caller_no_like, -> (*p){
    if p.is_a?(Array)
      phones = p.flatten
      unless (phones.select { |x| x.include?("%") }).empty?
        conds = phones.map { |d| "ani LIKE '#{d}'" }
        where(conds.join(" OR "))
      else
        conds = phones.map { |d| "'#{d}'" }
        where("ani IN (#{conds.join(",")})")
      end
    else
      where("ani LIKE ?",p)
    end
  }
  
  scope :dialed_no_like, -> (*p){
    if p.is_a?(Array)
      phones = p.flatten
      unless (phones.select { |x| x.include?("%") }).empty?
        conds = phones.map { |d| "dnis LIKE '#{d}'" }
        where(conds.join(" OR "))
      else
        conds = phones.map { |d| "'#{d}'" }
        where("dnis IN (#{conds.join(",")})")
      end
    else
      where("dnis LIKE ?",p)  
    end
  }
  
  scope :customer_name_like, ->(p){
    cus = Customer.select(:id).where(["name LIKE ?", p << "%"]).limit(50).all
    cus = (cus.map { |c| c.id }).concat([0])
    joins(:call_customer).where({call_customers: { customer_id: cus}})
  }
  
  scope :extension_no_in, -> (*p){
    exts = p
    where(extension: exts)  
  }
  
  scope :agent_in, -> (*p){
    where(agent_id: p)  
  }

  scope :group_in, -> (*p){
    joins(:group_member).where(["group_members.group_id IN (?)",p])
  }
  
  scope :taggings_in, -> (*p){
    where(["EXISTS (SELECT 1 FROM taggings WHERE taggings.tag_id IN (?) AND voice_logs.id = taggings.tagged_id)",p])
  }

  scope :keyword_in, -> (*p){
    where(["EXISTS (SELECT 1 FROM result_keywords WHERE result_keywords.keyword_id IN (?) AND voice_logs.id = result_keywords.voice_log_id)",p])
  }
  
  scope :days_ago, -> (d=0){
    d = Date.today - d
    start_time_bet(Time.parse(d.strftime("%Y-%m-%d") + " 00:00:00"),Time.now)
  }

  scope :today, ->{
    d = Date.today
    start_time_bet(Time.parse(d.strftime("%Y-%m-%d") + " 00:00:00"),Time.now)
  }
  
  scope :at_date, ->(d=nil){
    d = Date.today if d.nil?
    fr_d = Time.parse(d.strftime("%Y-%m-%d") + " 00:00:00")
    to_d = Time.parse(d.strftime("%Y-%m-%d") + " 23:59:59")
    start_time_bet(fr_d,to_d) 
  }
  
  scope :only_favourites_call, ->(p){
    joins(:call_favourites).where({ call_favourites: { user_id: p }})  
  }
  
  scope :default_filters, ->{
    where(["voice_logs.duration > 0"])
  }

  scope :main_call, -> {
    where(["voice_logs.ori_call_id IN ('1','')"])  
  }
  
  scope :call_type_in, ->(p){
    where(["EXISTS (SELECT 1 FROM call_classifications WHERE call_classifications.call_category_id IN (?) AND call_classifications.flag <> 'D' AND voice_logs.id = call_classifications.voice_log_id GROUP BY call_classifications.voice_log_id HAVING COUNT(0) = ?)",p,p.length])  
  }
  
  scope :atl_section_id_in, ->(p){
    p = [p] unless p.is_a?(Array)
    where("user_atl_attrs.section_id IN (?)", p)  
  }
  
  scope :repeat_dial_count_bet, ->(st_date, ed_date, count_fr, count_to, type_number=nil){
    cond = {
      sdate: st_date, edate: ed_date,
      count_from: count_fr, count_to: count_to,
      type_number: type_number
    }
    join_sql = PhonenoStatistic.create_joinsql_for_voice_logs(cond)
    joins(join_sql)
  }
  
  def self.force_index(index)
    from("#{self.table_name} FORCE INDEX(#{index})")
  end
  
  def call_direction_name
    case self.call_direction
    when 'i'
      'In'
    when 'o'
      'Out'
    else
      'Other'
    end
  end
  
  def details
    voice_file = temporary_file
    rcalls = []
    data = {
      id: self.id,
      call_id: self.call_id,
      call_direction: self.call_direction,
      call_direction_text: call_direction_name,
      start_time: self.start_time.to_formatted_s(:web),
      ani: self.ani,
      dnis: self.dnis,
      extension: self.extension,
      duration_sec: self.duration.to_i,
      duration_text: StringFormat.format_sec(self.duration),
      agent_name: agent_info.display_name,
      customer_name: customer_name,
      audio_channels: channel_details,
      voice_file_url: self.voice_file_url,
      temp_file_url: (voice_file.nil? ? nil : voice_file.url),
      releated_calls: rcalls
    }
    return data
  end
  
  def channel_details
    chan_agent = {
      id: self.agent_id,
      type: 'agent',
      display_name: nil,
    }
    chan_cust = {
      id: 0,
      type: 'customer',
      display_name: nil
    }
    return [chan_agent,chan_cust]
  end
  
  def agent_info
    unless defined? @user
      @user = self.user
      @user = User.new if @user.nil?
    end
    return @user
  end
  
  def voice_log_id
    self.id
  end
  
  def tag_list
    
    if defined? @tags
      @tags
    end
    
    taggings = self.taggings.all
    unless taggings.empty?
      tags = taggings.map { |t| t.tag_id }
      @tags = Tag.where(id: tags).order("name").all
    else
      @tags = []
    end
    
    @tags
    
  end
  
  def output_filename
    
    return [
      self.start_time.strftime("%Y%m%d_%H%M"),
      self.call_id.to_s
    ].join("_")
  
  end
  
  def have_url?
    return (self.voice_file_url.to_s.length > 1)
  end
  
  def temporary_file(opts={})
    if have_url?
      begin
        data_path = Settings.server.directory.audio_data
        out_type = Settings.callsearch.audio_format.to_sym
        if opts.has_key?(:audio_format)
          out_type = opts[:audio_format]
        end
        Rails.logger.debug "Trying to create temporary file for #{self.id}, format=#{out_type}"
        unless audio_temp_file_exist?(out_type)
          temp_file = nil
          downloaded_file = WorkingNet.file_download(self.voice_file_url, data_path)
          unless downloaded_file.nil?
            temp_file = AudioFileCrypto.decrypt(downloaded_file)
            temp_file = FileConversion.audio_convert(out_type, temp_file)
            temp_file = WorkingDir.file_rename(temp_file, "#{self.id}.#{out_type}")
            if File.exists?(downloaded_file)
              # remove downloaded file
              File.delete(downloaded_file)
            end
          end
        else
          temp_file = File.join(data_path, "#{self.id}.#{out_type}")
        end
        unless temp_file.nil?
          tm_file = TempFileDs.new(temp_file, temp_file.gsub(Settings.server.directory.public, Settings.server.docroot))
          return tm_file
        end
      rescue => e
        Rails.logger.error "Error to create temporary file for #{self.id}, #{e.message}"
      end
    end
    return nil
  end
  
  def desktop_activity
    
    stime = self.start_time
    etime = self.start_time + self.duration.to_i
    user_id = self.agent_id
    
    logs = UserActivityLog.exclude_idle.not_zero_duration.by_call_info(user_id, stime, etime).all
    logs = UserActivityLog.result_logs(logs, stime, etime)
    
    return logs
  
  end
  
  def emotion
    return VoiceLog.get_emotion_id(self.id)
  end
  
  def recognition_results
    self.call_transcriptions  
  end
  
  def recognizer_stats
    []  
  end
  
  def keyword_results
    []  
  end
  
  def more_attribute(attr_name)
    unless defined? @voice_log_attrs
      @voice_log_attrs = {}
      vatrs = VoiceLogAttribute.where({ voice_log_id: self.id }).all
      unless vatrs.empty?
        vatrs.each do |a|
          case a.attr_type
          when VoiceLogAttribute::ATTR_CALL_RESULT
            @voice_log_attrs[:call_result] = a.attr_val
          end
        end
      end
    end
    return @voice_log_attrs[attr_name]
  end
  
  def customer_name
    cu = self.customer
    unless cu.nil?
      return cu.name
    else
      return "Unknown"
    end
  end
  
  def agent_phone_no
    return (self.call_direction == 'o' ? self.ani : self.dnis)  
  end
  
  def customer_phone_no
    return (self.call_direction == 'o' ? self.dnis : self.ani) 
  end
  
  def self.get_emotion_id(id)
    emotion_id = id % 6
    if EmotionInfo.where(id: emotion_id).first.nil?
      return EmotionInfo.all.to_a.last
    end
    return EmotionInfo.where(id: emotion_id).first
  end

  def call_category_ids
    cates = CallClassification.where(voice_log_id: self.id)
    cates = cates.where.not(flag: "D")
    cates.select(:call_category_id).all.map { |cc| cc.call_category_id }
  end

  def call_stats_info
    csinfo = {
      call_id: self.call_id,
      voice_log_id: self.id,
      original_file_url: self.voice_file_url,
      ssdc: [self.site_id, self.system_id, self.device_id, self.channel_id].join("-"),
      filename: File.basename(self.voice_file_url)
    }
    return csinfo
  end
  
  def update_transcriptions(trans)
    doc = ElsClient::VoiceLogDocument.new(self.id)
    if doc.exists?
      doc.get_document
      doc.update_transcription(trans)
    end
  end
  
  def get_last_evaluated_form
    last_form = EvaluationCall.select(:evaluation_plan_id).where(voice_log_id: self.id)
    last_form = last_form.order(evaluation_log_id: :desc, id: :desc).first
    unless last_form.nil?
      return last_form.evaluation_plan_id
    end
    return nil
  end
  
  private
  
  def self.ransackable_scopes(auth_object = nil)
    %i(start_time_bet caller_no_like dialed_no_like extension_no_in group_in agent_in taggings_in keyword_in only_favourites_call main_call call_type_in customer_name_like repeat_dial_count_bet atl_section_id_in)
  end
  
  def audio_temp_file_exist?(out_fmt=nil)
    out_type = Settings.callsearch.audio_format.to_sym
    unless out_fmt.nil?
      out_type = out_fmt
    end
    au_fname = [self.id,out_type].join(".")
    au_fpath = File.join(WorkingDir.public_directory_path('audiodata'), au_fname)
    au_found = File.exists?(au_fpath)
    Rails.logger.debug "Checking temporary file #{au_fpath}, #{au_found}"
    return au_found
  end
  
  # end class
end
