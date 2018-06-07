require 'tilt'
require 'premailer'

class NotificationTemplate
  
  DialogProp = Struct.new(:width, :height)
  
  def initialize(params)
    @params = params
    @output = {}
    
    do_init
  end
  
  def render
    render_content
    render_popup_window
    
    return @output
  end
  
  def dialog
    return DialogProp.new(@width, @height)
  end
  
  private
  
  def do_init
    content_type = @params["content_type"].to_s.downcase
    case content_type
    when "keyword"
      init_keyword_notification
    when "faq"
      init_fag_notification
    end
    default_output
  end
  
  def init_keyword_notification
    p_keyword = @params["detected_keyword"]
    
    keyword = Keyword.where(id: p_keyword["keyword_id"]).first
    keyword_type = KeywordType.where(id: p_keyword["keyword_type_id"]).first
    keyword_name = p_keyword["keyword"]
    
    if (not keyword.nil?) and (not keyword_type.nil?)
      ntmp = keyword_type.notify_details2
      @output[:level] = ntmp["level"].to_s
      @output[:title] = ntmp["title"].to_s
      @output[:subject] = ntmp["subject"].to_s
      @output[:timeout] = ntmp["timeout"].to_i
      @output[:keyword_id] = keyword.id
      @output[:message_type] = "Keyword"
      @output[:play_sound_alert] = ntmp["desktop_sound"]
      @output[:cc_leader] = keyword_type.cc_leader?
      ntmp = keyword.notify_details2
      @output[:layout] = :keyword
      [:title, :subject].each do |otype|
        @output[otype] = @output[otype].gsub("[keyword]", keyword_name)
      end
      begin
        unless Rails.env == "production"
          @output[:title] << " :" + @params["voice_log_id"].to_s
        end
      rescue
      end
      @output[:content_list] = []
      
      begin
        ntmp["contents"].each do |cont|
          unless blank_content?(cont)
            @output[:content_list] << cont.gsub("[keyword]",keyword_name)
          end
        end
      rescue => e
        STDOUT.puts "error, no keyword contents"
      end
    end
  end
  
  def init_fag_notification
    faq_id = @params["faq_id"].to_i
    faq = FaqQuestion.by_faq_id(faq_id).first
    unless faq.nil?
      @output[:faq_id] = faq_id
      @output[:message_type] = "Recommendation"
      @output[:level] = "notice"
      @output[:title] = "Recommendation"
      @output[:layout] = :faq
      @output[:subject] = faq.question.to_s
      begin
        unless Rails.env == "production"
          @output[:title] << " :" + @params["voice_log_id"].to_s
        end
      rescue
      end
      @output[:html_content_template] = []
      @output[:content_list] = []
      list_ans = faq.get_faq_answers(@params["faq_answers_id"])
      list_ans.each do |ans|
        @output[:content_list] << ans
      end
    end
  end
  
  def default_output
    
    # content-type
    @output[:content_type] = @params["content_type"].to_s.downcase
    
    # level
    case @output[:level]
    when "notice", "info", "default"
      @output[:level] = "notice"
    when "warning", "error"
      @output[:level] = "warning"
    else
      @output[:level] = "notice"
    end
    
    # title
    if @output[:title].blank?
      @output[:title] = ""
    end
    
    # subject
    if @output[:subject].blank?
      @output[:subject] = ""
    end
    
    # timestamp
    if not @params.has_key?(:timestamp) or @params[:timestramp].blank?
      @output[:timestamp] = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end
    
    # timeout
    if @params[:timeout].to_i <= 0
      @params[:timeout] = 5
    end
    
    # other options
    @output[:play_sound_alert] = ((@output[:play_sound_alert] == "yes") ? true : false)
  end
  
  def render_content
    @output[:content] = ""
    
    # render content bases on layout
    case @output[:layout]
    when :keyword
      @output[:content] = render_with_keyword_layout
    when :faq, :recommendation
      @output[:content] = render_with_recommend_layout
    else
      @output[:content] = "<no specific layout>"
    end
    
    # cc message content to team lead
    unless @output[:cc_leader].nil?
      if @output[:cc_leader]
        @output[:cc_title] = "#{@output[:title]} - #{@params[:agent_display_name]}"
        @output[:cc_content] = remove_action_str(@output[:content])
      end
    end
    
  end
  
  def render_with_keyword_layout
    tsnow = Time.now.strftime("%H%M%S.%5N")
    act_url = "watchercli/log/#{@params[:message_id]}/#{@output[:keyword_id]}?read=true&ts=#{tsnow}"
    content_data = ""
    content_data << "<div data-action-url=\"#{act_url}\" data-item-type=\"btn\">#{@output[:subject]}</div>"
    unless @output[:content_list].empty?
      tmp_cont = "<div><ul>" + (@output[:content_list].map { |cont|
        "<li data-action-url=\"#{act_url}\" data-item-type=\"btn\">#{cont}</li>"
      }).join + "</ul></div>"
      content_data << tmp_cont
    end
    #Rails.logger.debug "Rendered result: #{content_data}"
    return content_data
  end
  
  def render_with_recommend_layout
    tsnow = Time.now.strftime("%H%M%S.%5N")
    content_data = ""
    unless @output[:content_list].empty?
      tmp_cont = "<ul>" + (@output[:content_list].map { |cont|
        act_url = "watchercli/log/#{@params[:message_id]}/#{@output[:faq_id]}?item_id=#{cont[:id]}read=true&ts=#{tsnow}"
        "<li data-action-url=\"#{act_url}\" data-item-type=\"btn\">#{to_inline_html(cont[:content])}</li>"
      }).join + "</ul>"
      content_data << tmp_cont
    end
    content_data = "<div><div class=\"block-left\">Customer said: #{@output[:subject]}</div><div class=\"block-right\">#{content_data}</div>#{comment_box_htm_for_faq}</div>"
    #Rails.logger.debug "Rendered result: #{content_data}"
    return content_data
  end
  
  def comment_box_htm_for_faq
    tsnow = Time.now.strftime("%H%M%S.%5N")
    act_url = "watchercli/log/#{@params[:message_id]}/#{@output[:faq_id]}?read=true&ts=#{tsnow}"
    return "<div class=\"block-comment\"><input type\"text\" name=\"comment\" maxlength=\"220\"/><button type=\"button\" data-action-url=\"#{act_url}\" data-item-type=\"btn\">Submit</button></div>"  
  end
  
  def md_content_to_html(cont)
    md_template = Tilt['md'].new {
      cont
    }
    return md_template.render
  end
  
  def render_popup_window
    # get popup template
    htm_template = Tilt.new(template_file)
    
    # render template as html
    rdata = {
      height: "#{@height}px",
      width: "#{@width}px",
      title: @output[:title],
      subject: @output[:subject],
      timestamp: @output[:timestamp]
    }
    
    begin
      htm_string = htm_template.render("",rdata)
    rescue => e
      STDOUT.puts "Error render popup message, #{e.message}"
      htm_string = ""  
    end
    
    # render html as inline-html
    opts = {
      with_html_string: true,
      css_string: css_data,
      remove_classes: true,
      remove_ids: true
    }
    
    preml = Premailer.new(htm_string, opts)
    html_str = preml.to_inline_css
    html_str = html_str.gsub(/\<(\?xml|(\!DOCTYPE[^\>\[]+(\[[^\]]+)?))+[^>]+\>/,"")
    html_str = html_str.gsub(/\<html\>\<body\>/,"")
    html_str = html_str.gsub(/(\<\/body\><\/html\>)/,"")
    html_str = html_str.gsub("\n","")
    
    @output[:dialog_height] = @height
    @output[:dialog_width] = @width
    @output[:notify_content] = html_str
  end
  
  def to_inline_html(htm_string)
    opts = {
      with_html_string: true,
      remove_classes: true,
      remove_ids: true
    }
    preml = Premailer.new(htm_string, opts)
    html_str = preml.to_inline_css
    html_str = html_str.gsub(/\<(\?xml|(\!DOCTYPE[^\>\[]+(\[[^\]]+)?))+[^>]+\>/,"")
    html_str = html_str.gsub(/\<html\>\<body\>/,"")
    html_str = html_str.gsub(/(\<\/body\><\/html\>)/,"")
    html_str = html_str.gsub("\n","")
    return html_str
  end
  
  def template_file
    fpath = (Dir.glob(File.join(template_directory,"#{@output[:level]}_*.html.erb"))).first
    strs = /^(\w+)_(\d+)x(\d+)/.match(File.basename(fpath))
    @width = strs[2].to_i
    @height = strs[3].to_i
    return File.join(fpath)
  end
  
  def blank_content?(cont)
    tcont = cont.gsub("<p><br></p>","")
    tcont = tcont.chomp.strip
    return (tcont.length <= 3)
  end
  
  def css_data
    css_file = File.join(template_directory, 'styles.css')
    return File.read(css_file)
  end
  
  def template_directory
    return File.join(Rails.root,'lib','templates','notifications')
  end
  
  def remove_action_str(text)
    # remove below patterns
    # 1. data-action-url=\"....\"
    # 2. data-item-type=\"btn\"
    text = text.gsub(/(data-action-url=)/,"(data-url=)")
    text = text.gsub("data-item-type=\"btn\"", "")
    return text
  end
  
  # end
end