class ConfigurationDetail < ActiveRecord::Base
  
  has_paper_trail
  
  belongs_to  :configuration
  belongs_to  :configuration_tree
  
end
