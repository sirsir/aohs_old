class TreeController < ApplicationController

  before_filter :login_required,:except => [:tree_source_xml]

  include AmiTree

  # ===============================================
  # User and Group Tree
  # ===============================================
  
  def tree_source

    op = {}
    op[:enabled_manager] = (params[:manager] == "false" ? false : true)
    op[:enabled_mycall] = (params[:mycall] == "false" ? false : true)
    op[:manager_filter] = (params[:managerfilt] == "false" ? false : true)
    op[:display_leader] = (params[:leader] == "false" ? false : true)
    op[:enable_unknow] = (params[:unknown] == "true" ? true : false)
    op[:agents] = (params[:agents] || "").split(",")
        
    src_tree = []
    src_tree = ami_build_tree(params[:node_type],params[:with_agent],params[:usr],params[:filter],op)

    render :layout => false, :text => src_tree.to_json

  end

  def tree_source_xml

    src_tree = []

    node_type = "text"
    with_agent = true
    user_id = params[:user_id]

    op = {}
    op[:enabled_manager] = true
    op[:enabled_mycall] = true
    op[:manager_filter] = true
    op[:display_leader] = true
    
    src_tree = ami_build_tree(node_type,with_agent,user_id,op)

    send_data src_tree.to_xml, {:type => 'text/xml', :filename => 'agents_tree.xml'}

  end

  def tree_source_agents
  
    group_id = params[:grp].to_i
      
    src_tree_agents = ami_tree_agents(group_id,params[:node_type]);
    
    render :layout => false, :text => src_tree_agents.to_json
        
  end
  
  # ===========================================================
  # Configuration Tree
  # ===========================================================
  
  def tree_config
  
    node_type = "text"
    
    parent_types = [
      {:type => node_type,:label => "Server",:expanded => true,:id => "SVR",'NodeType' => 'server','NodeId' => 'S', :children => []},
      {:type => node_type,:label => "Client",:expanded => true,:id => "CLI",'NodeType' => 'client','NodeId'=> 'C', :children => []}
    ]
    node_load = [{:type => node_type,:label => "Loading",:expanded => false,:id => "LOAD",'NodeType' => 'load','NodeId'=> 'L'}]
      
    src_cfg = []
      
    parent_types.to_a.each do |p|
      cf_groups = ConfigurationGroup.where({ :configuration_type => p['NodeId'] }).group('name').all
      unless cf_groups.empty?
        p[:children] = []
        cf_groups.each do |g|
          cfg = {:type => node_type,:label => g.name.upcase,:expanded => false,:id => g.id,'NodeParent' => "#{p['NodeType']}.#{g.name}.default",'NodeType' => 'default','GroupId'=> g.id, 'ModeDisp' => 2}
          
          cfg[:children] = []
          cfg[:children] << {:type => node_type,:label => "BaseLine",:expanded => false,:id => "BLI",'NodeParent' => "#{p['NodeType']}.#{g.name}.baseline", 'NodeType' => 'baseline','NodeId'=> 'B', 'ModeDisp' => 1}
          cfg[:children] << {:type => node_type,:label => "Groups",:expanded => false,:id => "GRP",'NodeParent' => "#{p['NodeType']}.#{g.name}.groups",'NodeType' => 'groups','NodeId'=> 'G', :children => node_load, 'ModeDisp' => 3}
          cfg[:children] << {:type => node_type,:label => "Users",:expanded => false,:id => "USR",'NodeParent' => "#{p['NodeType']}.#{g.name}.users",'NodeType' => 'users','NodeId'=> 'U', :children => node_load, 'ModeDisp' => 4}
          
          p[:children] << cfg    
        end
      end
      src_cfg << p
    end

    render :layout => false, :text => src_cfg.to_json
    
  end
  
  def tree_config_member
    
    node_type = "text"
    src_members = []
             
    case params[:type] 
    when /^groups/
      groups = Group.order('name')
      unless groups.empty?
        groups.each do |g|
          src_members << {:type => node_type,:label => g.name,:expanded => false,:id => "G-#{g.id}",'NodeLabel' => g.name,'NodeType' => 'group','GroupId'=> g.id, 'ModeDisp' => 3}
        end
      end
    else
      usrs = User.order('login')
      unless usrs.empty?
        usrs.each do |u| 
          src_members << {:type => node_type,:label => u.login,:expanded => false,:id => "U-#{u.id}",'NodeLabel' => u.login,'NodeType' => 'user','UserId'=> u.id, 'ModeDisp' => 4}
        end
      end
    end
    
    render :layout => false, :text => src_members.to_json
    
  end
    
end
