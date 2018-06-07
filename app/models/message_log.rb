class MessageLog < ActiveRecord::Base
  
  belongs_to  :receiver, class_name: "User", foreign_key: :who_receive
  belongs_to  :voice_log
  
  scope :find_log, ->(uuid, ref_id=nil){
    t = 1.days.ago.strftime("%Y-%m-%d %H:%M:%S")
    unless ref_id.nil?
      where(["created_at >= ? AND message_uuid = ? AND reference_id = ?", t, uuid, ref_id])  
    else
      where(["created_at >= ? AND message_uuid = ?", t, uuid])  
    end
  }
  
  scope :created_date_betw, ->(from_date,to_date) {  
    where("created_at BETWEEN :from_time AND :to_time",from_time: from_date, to_time: to_date)
  }
  
  scope :only_recommendation, ->{
    where(message_type: "Recommendation")
  }
  
  scope :by_receiver, ->(v){
    users = User.select(:id).name_like(v).all
    where(who_receive: users.map { |u| u.id })
  }
  
  scope :order_by, ->(p) {
    incs      = []
    order_str = resolve_column_name(p)
    includes(incs).order(order_str)
  }
  
  def set_read
    self.read_flag = "Y"
    save
  end
  
  def set_useful
    self.useful_flag = "Y"
    save
  end
  
  def set_popup_desktop(t)
    self.display_cli_at = t
    self.display_at = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    save
  end
  
  def log_type_name
    case self.message_type.to_s.downcase
    when "keyword"
      return "Keyword"
    when "recommendation", "faq"
      return "Recommendation"
    end
    return "Unknown"
  end
  
  def acknowledge_date
    if acknowledged?
      return self.updated_at
    end
    return nil
  end
  
  def detected_result_at
    if debug_info? and defined? @debug_info.detected_rs_at
      return (@debug_info.detected_rs_at.is_a?(String) ? Time.parse(@debug_info.detected_rs_at) : @debug_info.detected_rs_at) 
    end
    return nil
  end
  
  def detected_result_at_dsp
    return (detected_result_at.nil? ? "" : detected_result_at.to_formatted_s(:time))
  end

  def ut_ended_at
    if debug_info? and defined? @debug_info.dsr_ut_ended_at
      return (@debug_info.dsr_ut_ended_at.is_a?(String) ? Time.parse(@debug_info.dsr_ut_ended_at) : @debug_info.dsr_ut_ended_at)
    elsif not self.dsr_ut_ended_at.nil?
      return self.dsr_ut_ended_at
    end
    return nil
  end
  
  def ut_ended_at_s
    return (ut_ended_at.nil? ? nil : ut_ended_at.strftime("%H:%M:%S"))
  end
  
  def seqment_position
    if debug_info?
      if defined? @debug_info.start_msec
        return @debug_info.start_msec
      end
    end
    return nil
  end
  
  def seqment_position_t
    unless seqment_position.nil?
      return StringFormat.format_sec(@debug_info.start_msec.to_i/1000.0).to_s
    end
    return nil
  end
  
  def receiver_info
    unless self.receiver.nil?
      return self.receiver
    end
    return User.new
  end
  
  def acknowledged?
    return (self.read_flag == "Y")  
  end
  
  def voice_log_info
    unless defined? @voice_log
      @voice_log = self.voice_log
      if @voice_log.nil?
        @voice_log = VoiceLog.new
      end
    end
    return @voice_log
  end
  
  def time_at_of_call(fmt=false)
    if debug_info? and defined? @debug_info.start_msec
      return (fmt ? StringFormat.format_sec(@debug_info.start_msec.to_i/1000.0) : @debug_info.start_msec)
    end
    return nil
  end
  
  def message_description
    # html display
    case self.message_type.to_s.downcase
    when "keyword"
      return detail_for_keyword
    when "recommendation", "faq"
      return detail_for_faq
    end
    return nil
  end
  
  def detected_sentence
    if debug_info? and defined? @debug_info
      return @debug_info.detected_sentence
    end
    return nil
  end
  
  def store_message_detail(data)
    # this data will be saved to ES <message_log>
    mlog = data.select { |k,v|
      selected_es_fields.include?(k.to_s)
    }
    begin
      mlog["id"] = self.id
      mlog = ElsClient::MessageLogDocument.new(mlog)
      mlog.create
    rescue => e
      Rails.logger.error "Error update es message log, #{e.message}"
    end
  end
  
  def debug_info?
    unless defined? @debug_info
      ml = MessageLogsIndex::MessageLog.query(term: { _id: self.id })
      @debug_info = ml.to_a.first
      return !@debug_info.nil?
    end
    return !@debug_info.nil?
  end

  def speech_at
    v = voice_log_info
    unless v.start_time.nil?
      if self.end_msec.to_i > 0
        return v.start_time + (self.end_msec.to_f/1000.0)
      else
        if debug_info? and defined? @debug_info.end_msec
          return v.start_time + (@debug_info.end_msec.to_f/1000.0)
        end
      end
    end
    return nil
  end
  
  def speech_at_t
    return (speech_at.nil? ? nil : speech_at.strftime("%H:%M:%S"))
  end
  
  def speech_at_t2
    txt = (speech_at.nil? ? nil : speech_at.strftime("%H:%M:%S")).to_s
    txt << " (#{seqment_position_t})"
  end
  
  def speech_at_t3
    frto = []
    if debug_info?
      if defined? @debug_info.start_msec
        frto << StringFormat.format_sec(@debug_info.start_msec.to_i/1000.0)
      elsif self.start_msec.to_i > 0
        frto << StringFormat.format_sec(self.start_msec.to_f/1000.0)
      end
      if defined? @debug_info.end_msec
        frto << StringFormat.format_sec(@debug_info.end_msec.to_i/1000.0)
      elsif self.end_msec.to_i > 0
        frto << StringFormat.format_sec(self.end_msec.to_f/1000.0)
      end
    end
    txt = (speech_at.nil? ? nil : speech_at.strftime("%H:%M:%S")).to_s
    txt << " (#{frto.join("-")})"
    return txt
  end
  
  def accepted_result_at_t
    return (self.dsr_rs_accepted_at.nil? ? nil : self.dsr_rs_accepted_at.strftime("%H:%M:%S"))
  end
    
  def call_start_time
    v = voice_log_info
    unless v.start_time.nil?
      return v.start_time
    end
    return nil
  end
  
  def call_start_time_t
    unless call_start_time.nil?
      return call_start_time.strftime("%Y-%m-%d %H:%M:%S")
    end
    return nil
  end
  
  def faq_info
    rfaq = {}
    faq = FaqQuestion.where(id: self.reference_id.to_i).first
    unless faq.nil?
      rfaq[:question] = faq.question
      if debug_info?
        rfaq[:answers_c] = ""
        anss = FaqAnswer.where(id: @debug_info.faq_answers_id).limit(3).all
        anss.each_with_index do |ans,i|
          rfaq[:answers_c] << "<div>#{ans.content}</div>"
        end
      end
    end
    return rfaq
  end
  
  private
  
  def selected_es_fields
    return [
      "voice_log_id",
      "content_type",
      "agent_id",
      "faq_id",
      "faq_answers_id",
      "keyword_id",
      "message_id",
      "who_receive_id",
      "start_msec",
      "detected_sentence",
      "detected_keyword",
      "sent_msg_at",
      "detected_rs_at",
      "received_rs_at"
    ]
  end
  
  def self.resolve_column_name(str)  
    unless str.empty?
    end
    return str
  end

  def self.ransackable_scopes(auth_object = nil)
    %i(created_date_betw by_receiver)
  end
  
  def detail_for_keyword
    keyword = Keyword.where(id: self.reference_id).first
    unless keyword.nil?
      return "<label>Keyword</label>: #{keyword.name}"
    end
    return nil
  end
  
  def detail_for_faq
    line_break = "\r\n"
    faq = FaqQuestion.where(id: self.reference_id.to_i).first
    unless faq.nil?
      txt = ["<label>Question</label>: #{faq.question}"]
      faqa = FaqAnswer.where(id: self.item_id.to_i).first
      unless faqa.nil?
        txt << "<label>Result</label>: #{faqa.content}"  
      end
      # comment from client
      if self.comment.to_s.length > 0
        txt << "<label>Comment</label>: #{self.comment}"
      end
      # display result
      if debug_info?
        anss = FaqAnswer.where(id: @debug_info.faq_answers_id).limit(3).all
        txt << "<label>Display Items:</label>"
        anss.each_with_index do |ans,i|
          txt << "<div>#{ans.content}</div>"
        end
        if defined? @debug_info.detected_sentence
          txt << "<label>Sentence:</label> #{@debug_info.detected_sentence}"
        end
      end
      return txt.join("<br/>#{line_break}")
    end
    return nil
  end
  
end
