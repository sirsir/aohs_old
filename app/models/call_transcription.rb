class CallTranscription < ActiveRecord::Base
  
  def self.parse_raw_result(logs)
    output = []
    logs.each_with_index do |log, i|
      output << map_row_result(log, i)
    end
    return output
  end
  
  def self.result_log(raw)
    return parse_raw_result(raw)
  end

  def self.highlight_keywords(logs, keywords)
    ologs = []
    unless logs.blank?
      ologs = logs.map { |l| insert_keyword_symbol(l, keywords) }
    end
    return ologs
  end
  
  private
  
  def self.map_row_result(log, i)
    return {
      no: i+1,
      type: log.speaker_type_name.downcase,
      title: log.speaker_type_name,
      ssec: log.start_sec,
      esec: log.end_sec,
      stime: StringFormat.format_sec(log.start_sec),
      result: (Settings.callsearch.reformat_sentence ? StringFormat.sentense_format(log.result) : log.result),
      channel: log.channel,
      duration: log.duration_sec,
      edited_flag: log.edited_flag,
      org_result: log.org_result
    }
  end
  
  def self.insert_keyword_symbol(log, keywords)
    begin
      words = keywords[:list][log[:channel]].uniq
      unless words.nil?
        words.each do |w|
          log[:result] = log[:result].gsub(/(#{w[:text]})/,"<span class=\"content-keyword #{w[:css_class]}\">#{w[:text]}</span>")  
        end
      end
    rescue
    end
    return log
  end
  
end