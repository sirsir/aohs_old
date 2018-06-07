class ConfigurationTree < ActiveRecord::Base

  NODE_TYPES    = [:base]
  ORDERS        = "FIELD(configuration_trees.node_type,'default','base','user')"
  
  belongs_to    :configuration_group
  has_one       :configuration_detail
  
end
