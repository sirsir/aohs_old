module ReportsHelper
  
  def li_report_tag(title, options={})
    if allow_access_link?(options)
      htm_class = ['item']
      htm_class << "selected" if match_url_options?(options, params)
      content_tag :li, class: htm_class.join(" ") do
        content_tag :a, title: title, href: url_for(options) do
          concat(content_tag :span, title)
        end
      end
    else
      nil
    end
  end
  
  private
  
  def allow_access_link?(url_options)
    return can_do?(url_options[:controller], get_action_name(url_options))
  end
  
  def match_url_options?(params1, params2)
    bln = true
    params1.each do |k,v|
      bln = params2[k] == v
      break unless bln
    end
    return bln
  end
  
  def get_action_name(url_options)
    # format action_name.link_name
    name = url_options[:action].clone
    if url_options[:row_by].present?
      name << ".#{url_options[:row_by]}"
    end
    if url_options[:col_by].present?
      name << ".#{url_options[:col_by]}"
    end
    return name
  end
  
end
