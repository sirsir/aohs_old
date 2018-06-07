class Configuration < ActiveRecord::Base
  
  has_paper_trail
  
  belongs_to    :configuration_group
  has_many      :configuration_details
  has_many      :configuration_trees, through: :configuration_details
  
  def get_default
  
    c_vals = find_values
    
    c_vals.first
  
  end
  
  def get_value

    c_vals = find_values
    
    c_vals.last
    
  end
  
  def set_config_for(node_type='default',node_id=0)
    
    @node_type = node_type
    @node_id   = node_id
  
  end
  
  private
  
  def find_values
    
    unless defined? @c_vals
      @c_vals = []
      confs = ConfigurationDetail.joins([:configuration_tree])
              .select("configuration_trees.node_type,configuration_trees.node_id,configuration_details.conf_value")
              .where(configuration_id: self.id).order(ConfigurationTree::ORDERS).all
      
      unless confs.empty?
        confs.each do |cf|
          @c_vals << cf.conf_value.to_s
          break if cf.node_type == @node_type
        end
      end
    end
    
    if @c_vals.length > 2
      @c_vals = @c_vals.slice(-2)
    end
    
    ## [default, current_value]
    return @c_vals 

  end
  
end
