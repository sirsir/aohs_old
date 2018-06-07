require 'utils/text_segmenter'

module StringFormat
  
  def self.format_sec(sec, short = false)
    
    sec = sec.to_i

    if short
      unit = ["h", "m", "s"]
    else
      unit = [" hour", " min", " sec"]
    end

    format = []
    hour = sec / 3600

    if hour > 0
      if hour < 10
        format << "0#{hour}"
      else
        format << "#{hour}"
      end
      sec %= 3600
    else
      format << "00"
    end

    min = sec / 60
    if min > 0
      if min < 10
        format << "0#{min}"
      else
        format << "#{min}"
      end
      sec = sec % 60
    else
      format << "00"
    end

    if sec < 10
      format << "0#{sec}"
    else
      format << "#{sec}"
    end

    format.join(":")

  end
  
  def self.secs_humanize(secs)
    options = {
      format: Settings.statistics.reporting.duration_format.to_sym,
      limit_to_hours: true,
      keep_zero: true,
      hours: true
    }
    return ChronicDuration.output(secs, options)
  end
  
  def self.days_humanize(days)

    if days.nil?
      return nil
    end
    
    years  = 365
    months = 12

    y = days/years
    m = days%years/30
    d = days%years%30
    
    if y > 0
      return "#{y} years #{m} months"
    elsif m > 0
      return "#{m} months"
    else
      return "#{d} days"
    end
  
  end
  
  def self.sentense_format(txt)
    return TextSegmenter.add_sentense_segmenter(txt)
  end
  
  def self.highlight_text(text, phrases)
    if text.blank? || phrases.blank?
      return { text: text || "", count: 0 }
    else
      output_text = text
      phrases = (phrases.map { |x| x.gsub("\"","") }).uniq
      match = Array(phrases).map do |p|
        Regexp === p ? p.to_s : Regexp.escape(p)
      end.join('|')
      output_text = text.gsub(/(#{match})/, "<em>\\1</em>")
      score = (output_text.split("<em>")).length - 1
      return {
        text: output_text,
        count: score
      }
    end
  end
  
  def self.duration_reporting_format(sec=0,sec_default=0)
    begin
      options = {
        format: :chrono,
        limit_to_hours: true,
        keep_zero: true,
        hours: true
      }
      sec = sec.to_i if sec.is_a?(String)
      unless sec.blank?
        txt = ChronicDuration.output(sec, options)
        txt = add_zero_time_padding(txt)
      else
        txt = ChronicDuration.output(sec_default, options)
      end
      return txt
    rescue => e
      Rails.logger.error "Can not formatting value '#{sec}' to duration format"
    end
    return sec
  end
  
  def self.pct_format(f)  
    sprintf("%0.2f",f.to_f)
  end
  
  def self.num_format(f)
    return f.to_f.round(2)
  end
  
  def self.score_fmt(f)
    sprintf("%0.2f", f.to_f.round(2))
  end

  def self.format_phone(phone)
    p = PhoneNumber.new(phone)
    return p.formatted_s
  end
  
  def self.format_ext(ext)
    p = PhoneNumber.new(ext)
    return p.formatted_s
  end
  
  def self.number_delm(n)
    return ActiveSupport::NumberHelper::number_to_delimited(n, delimiter: ',')
  end
  
  def self.html_sanitizer(h_str)
    return ActionView::Base.full_sanitizer.sanitize(h_str)
  end
  
  private
  
  def self.add_zero_time_padding(t)
    #
    # add zero padding for time format
    # format 00:00:00
    #
    txt = t.split(":")
    (3 - txt.length).times {
      |x| txt.insert(0,0)
    }
    txt = (txt.map { |x| sprintf("%02d", x.to_i) }).join(":") 
    return txt
  end
  
  # end class
end