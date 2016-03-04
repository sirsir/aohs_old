module ApplicationHelper

  include AmiPermission
  include Format

  ##$PER_PAGE = $CF.get('client.aohs_web.number_of_display_list') 

  $VOLUME_RANK = [0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,1.2,1.4,1.6,2.0,2.5,3.0,4.0,5.0,7.0,10.0]
  $SPEED_RANK = [0.5,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.0,2.2,2.4]

   def get_web_root_url
     host_url = "http://#{request.host_with_port}"
     request_url = request.url.to_s.gsub(host_url,'')  
     unless params.blank?
        params.each_pair do |x,v|
          request_url= request_url.gsub(v,'')
        end
        request_url = request_url.gsub('/','')
        if not request_url.strip.empty?
          request_url = "/#{request_url}"
        end
     end
     return "#{host_url}#{request_url}"
  end

  def get_root_url
    return Aohs::SITE_ROOT
  end
  
  def link_image_tag(name='',image='',option={},html_option={})
    
    # note...
    # id format: img_tag => "<id>"
    # id format: a_tag => "<id>-a"
    
    html = ""
    html << link_to(image_tag(image, :align => 'absmiddle', :border => 0), option, html_option)
    html << ' '
    if html_option.has_key?(:id)
      new_html_option = {:id => html_option.fetch(:id)+ "-a"}
      html_option = html_option.merge(new_html_option)
    end
    if name.length > 0
      html << link_to(name, option, html_option)
    end

    return html.html_safe
    
  end
    
  #
  # For make header link
  #
  def create_header_link(name,url,title,current_controller,map_controllers)
    li_class = current_header_menu(current_controller,map_controllers)
    url_tag = link_to(name,url,{:class =>'a-link-2',:title => title})
    return "<li class=\"#{li_class}\">#{url_tag.gsub("\"","'")}</li>".html_safe
  end
  
  def current_header_menu(control_name,link_name)
    if link_name.is_a?(String)
      link_name = [link_name]
    end
    if link_name.include?(control_name)
      return "selected"
    else
      return "unselected"
    end    
  end
  
  
  def javascript_src_path(src)

    return "<script src=\"#{javascript_path(src)}\" type=\"text/javascript\"></script>".html_safe

  end

  def files_src_path(src)

    return javascript_path(src)

  end
  
  def stylesheet_src_path(src)

     return "<link href=\"#{stylesheet_path(src)}\" type=\"text/css\" rel=\"stylesheet\"/>".html_safe

  end

  def image_src_path(src)

    return image_path(src)
      
  end

  def display_frm_error(message)

    str = ""
    unless message.blank?
      if message.is_a?(String)
        str = "<div class=\"div-frm-message\">#{message}</div>"
      else
        str = "<div class=\"div-frm-message\">#{message.join('<br>')}</div>"
      end
    end

    return str.html_safe

  end

  def display_frm_success(message)

    str = ""
    unless message.blank?
      if message.is_a?(String)
        str = "<div class=\"div-frm-notice\">#{message}</div>"
      else
        str = "<div class=\"div-frm-notice\">#{message.join('<br>')}</div>"
      end
    end

    return str.html_safe

  end

  def limit_string(str,length=10)
    str = "" if str.nil?
    if not str.empty?
        new_str = ""
        i = 0
        str.each_char do |c|
          i += 1
          if i >= length
            new_str << c
            new_str << "..."
            break
          else
            new_str << c
          end
        end
        str = new_str
    end
    return str
  end
  
  def display_cti_id(cti)
	
  	#if cti.nil?
  	#	return ""
  	#else
  	#	return sprintf("%05d",cti)
  	#end
	
    if cti.blank?
      return ""
    else
      return cti.to_s.strip
    end
    
  end
  
  def weekly_picker(name,current_week="2100-01-01",weeks=6*4)
    
    week = Time.new.beginning_of_week
    current_week = "2100-01-01" if current_week.blank?
    current_week = Time.parse(current_week + " 00:00:00") unless current_week.nil?
    current_week = (name.to_s == "fr" ? current_week.beginning_of_week : current_week.end_of_week)
      
    html = ""
    html << "<select name=\"#{name.to_s}\">"
    html << "<option></option>"
    g = ""
    weeks.times do |i|
      tmp = (name.to_s == "fr" ? week : week.end_of_week)
      selected = (current_week.to_date == tmp.to_date) ? "selected" : ""
      if g != tmp.beginning_of_week.strftime("%Y-%b")
        g = tmp.beginning_of_week.strftime("%Y-%b")
        html << "<OPTGROUP LABEL=\"#{g}\">"
      end
      html << "<option #{selected} value=\"#{tmp.strftime("%Y-%m-%d")}\">#{tmp.beginning_of_week.strftime("%Y-%b,")} #{tmp.beginning_of_week.strftime("%d")}-#{tmp.end_of_week.strftime("%d")}</option>"
      week = (week - (60*60*24)).beginning_of_week
      if g != tmp.beginning_of_week.strftime("%Y-%b")
        html << "</OPTGROUP>"
      end        
    end
    html << "</select>"
    
    return html.html_safe
    
  end
  
  def monthly_picker(name,current_month="2100-01-01",months=10)
    
    month = Time.new.beginning_of_month
    current_month = "2100-01-01" if current_month.blank?
    current_month = Time.parse(current_month + " 00:00:00") unless current_month.nil?
    
    html = ""
    html << "<select name=\"#{name.to_s}\">"
    html << "<option></option>"
    months.times do |i|
      tmp = (name.to_s == "fr" ? month : month.end_of_month)
      selected = (current_month.strftime("%Y-%m") == tmp.strftime("%Y-%m")) ? "selected" : ""
      html << "<option #{selected} value=\"#{tmp.strftime("%Y-%m-%d")}\">#{tmp.strftime("%Y-%b")}</option>"
      month = (month - (60*60*24)).beginning_of_month
    end
    html << "</select>"
    
    return html.html_safe
       
  end
  
  def car_id_format(car_no=nil)
    if car_no.blank?
      return ""
    else
      c = format_car_id(car_no).to_s.split(/-| /,3)
      return  "<span class='carunderline'>" + c[0] + "</span>" + "-" + "<span class='carunderline'>" + c[1] + "</span>" + "&nbsp;" + "<span class='carunderline'>" + c[2] + "</span>"
    end
  end
  
end
