if Rails.env.development? or Rails.env.test?
  
  Fabrication.configure do |config|
    
    config.fabricator_path  = 'test/fabricators'
    config.path_prefix      = Rails.root
    config.sequence_start   = 1
    
  end
  
end

