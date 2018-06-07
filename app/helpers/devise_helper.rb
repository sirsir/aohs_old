module DeviseHelper
  
  def devise_error_messages!
    
    alerts = []

    if !flash.empty?
      #alerts.push(flash[:error]) if flash[:error]
      #alerts.push(flash[:alert]) if flash[:alert]
      #alerts.push(flash[:notice]) if flash[:notice]
    end

    return "" if resource.errors.empty? && alerts.empty?
    
    errors   = resource.errors.empty? ? alerts : resource.errors.full_messages
    messages = errors.map { |msg| content_tag(:li, msg) }.join
    
    html = <<-HTML
    <div id="error_explanation">
      <ul>#{messages}</ul>
    </div>
    HTML

    html.html_safe

  end
  
end