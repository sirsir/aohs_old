JsRoutes.setup do |config|
  
  # set relative url in js
  unless Rails.application.config.relative_url_root.nil?
    config.prefix = Rails.application.config.relative_url_root
  end
  
end