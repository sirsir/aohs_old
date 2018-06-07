class ContentStyleController < ApplicationController
  
  def content_style
    content_type = params[:type]
    
    case content_type
    when "program"
      @cc = ProgramInfo.all
    when "keyword"
      @cc = Keyword.all
    when "emotion"
      @im = CallEmotion.emotion_icons
    when "call_category"
      @cates = CallCategory.all
    when "telephone"
      @tels = TelephoneInfo.style_list
    end
  end
  
end
