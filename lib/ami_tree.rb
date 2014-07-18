 
module AmiTree
  
  NODE_TYP_USRN   = "agent"
  NODE_TYP_GRPN   = "group"
  NODE_TYP_CATN   = "cate"
  
  ICON_USRN       = "ico-usr"
  ICON_GRPN       = "ico-grp"
  ICON_CATN       = "ico-cate"
  
  TREE_NAME       = "aohstreeview"
  TREE_LEVELS     = [['My','Manager','Category'],['Group'],['Agent']]
  
  #=========================================================#
  # build nodes of agents tree with group and role permission
  # build_tree return tree nodes
  # support YUI tree
  #=========================================================#
  # Main

  def ami_build_tree(node_type,with_agent,user_id=nil,use_filter=true,op={:enabled_manager => true, :manager_filter => true, :enable_mycall => true, :display_leader => true, :enable_unknow => false})

    tree = []

    user = ""

    if user_id.nil?
      user = current_user.login.to_s
    else
      user = user_id.to_i
    end

    @use_filter = enabled_tree_filter(use_filter)
    @node_type = tree_node_type(node_type)
    @with_agent = tree_with_agent(with_agent)
    @my_groups, owner = display_groups(user)
    @userinfo = owner
    @display_leader = op[:display_leader]
    @selected_agents = find_selected_agent(op[:agents])

    $GRP_INFO = groups_infomation(@my_groups)

    # cate types list
    gcts = tree_node_level

    # build tree
    tree = build_category_tree(gcts,[])
      
    if op[:enable_unknow] == true
      unknow_node = build_unknow_agent_node()
      tree = tree.insert(0,unknow_node) unless unknow_node.nil?
    end
    
    if op[:enabled_manager] == true
      manager_node = build_manager_tree({:manager_filter => op[:manager_filter]})
      tree = tree.insert(0,manager_node) unless manager_node.nil?
    end
    
    if op[:enabled_mycall] == true
      mycall_node = build_mycall_node()
      tree = tree.insert(0,mycall_node) unless mycall_node.nil?
    end
    
    return tree

  end

  def ami_tree_agents(group_id,node_type)
    
    @with_agent = true
    @display_leader = true
    @node_type = tree_node_type(node_type)
    @selected_agents = {}
      
    data = []
      
    g = Group.where({:id => group_id}).first
    unless g.nil?
      data = build_agent_tree(g.id)
    end
    
    return data
    
  end
    
  #=========================================================#
  # Tree

  def build_category_tree(gcts,gc_ids)

    data = []

    gct_id = gcts.first[:id]
    gcs = find_category_list(gct_id,gc_ids)

    unless gcs.empty?
      gcs.each do |gc|
        child = []

        gc_ids << gc[:id]
        next_gct = Array.new(gcts)
        next_gct.delete(gcts.first)

        # category
        if not next_gct.nil? and not next_gct.empty?
          child = build_category_tree(next_gct,gc_ids)
        else
          child = []
          child = build_group_tree(gc_ids)
        end

        if child.empty?
          data << {:type => @node_type,:label => "#{gc[:name]}",:labelStyle => 'icon-gc',:expanded => true,:id => gc[:id],:NodeType => NODE_TYP_CATN,:NodeId => gc[:id] }
        else
          data << {:type => @node_type,:label => "#{gc[:name]}",:labelStyle => 'icon-gc',:expanded => true,:id => gc[:id],:NodeType => NODE_TYP_CATN,:NodeId => gc[:id],:children => child }
        end

        gc_ids.delete(gc_ids.last)

      end
   
      if not gc_ids.empty?    
        group_childs = build_group_tree(gc_ids)
        unless group_childs.empty?
          group_childs.each do |grp|
            data << grp
          end
        end
      end

    else
      if not gc_ids.empty?
        group_childs = build_group_tree(gc_ids)
        unless group_childs.empty?
          group_childs.each do |grp|
            data << grp
          end
        end
      end
    end


    return data

  end

  def build_group_tree(gc_ids)

    data = []

    groups = find_group_list(gc_ids)

    unless groups.empty?
      groups.each do |x|
        child = build_agent_tree(x.id)
        if child.empty?
          data << {:type => @node_type,:label => x.name.to_s.strip,:labelStyle => 'icon-grp',:expanded => false,:id => x.id,:NodeType => NODE_TYP_GRPN,:NodeId => x.id, :GroupId => x.id }
        else
          data << {:type => @node_type,:label => x.name.to_s.strip,:labelStyle => 'icon-grp',"iconMode" => 1 ,:expanded => true,:id => x.id,:NodeType => NODE_TYP_GRPN,:NodeId => x.id,:GroupId => x.id,:children => child }
        end
      end
    end

    return data

  end

  def build_agent_tree(grp_id)

    data = []
    
    select_agent = @selected_agents[grp_id.to_s] || []
    
    if @with_agent or not select_agent.blank?
      agents = find_agent_list(grp_id)
      if @display_leader == true
        leader = build_leader_node(grp_id)
        data << leader unless leader.nil?
      end
      unless agents.empty?
        agents.each do |x|
          checked = false
          if(select_agent.include?(x.id.to_i))
            checked = true
          end
          data << {:type => @node_type,:label => x.login.to_s.strip,:labelStyle => 'icon-usr',:id => x.id, :checked => checked,:NodeType => NODE_TYP_USRN,:NodeId => x.id }
        end
      end
    end

    return data

  end

  def build_leader_node(grp_id)

    data = nil

    if grp_id.to_i > 0
      leader = Group.where({:id => grp_id.to_i}).first
      unless leader.nil?
        unless leader.leader_id.nil?
          user = User.where({:id => leader.leader_id}).first
          unless user.nil?
            role = (user.role.nil? ? "Leader" : user.role.name) 
            data = {:type => @node_type,:label => "#{user.login} [#{role}]",:labelStyle => 'icon-usr',:id => user.id,:NodeType => NODE_TYP_USRN,:NodeId => user.id }
          end
        end 
      end
    end

    return data
    
  end

  def build_mycall_node()

    data = nil
    if permission_by_name('tree_mycall')
      data = {:type => @node_type,:label => "MyCalls [#{@userinfo.login}]",:labelStyle => 'icon-usr',:id => @userinfo.id,:NodeType => NODE_TYP_USRN,:NodeId => @userinfo.id }
    end
    
    return data

  end
  
  def build_unknow_agent_node()

    select_agent = @selected_agents['0'] || []
    checked = false
    if select_agent.include?(0)
      checked = true
    end  
    
    data = nil
    data = {:type => @node_type,:label => "UnknownAgents",:labelStyle => 'icon-usr',:checked => checked,:id => 0,:NodeType => NODE_TYP_USRN,:NodeId => 0}
    
    return data
            
  end
  
  def build_manager_tree(op={})

    select_manager = @selected_agents['0'] || []
      
    data = []
    group_managers = []
    if op[:manager_filter] == true
      group_managers = GroupManager.where({:user_id => @userinfo.id })
      mg_id = group_managers.map {|m| m.manager_id}
      mg_id.delete_if { |m| m == @userinfo.id }
      group_managers = Manager.where({:id => mg_id }).order("users.login")
    else
      group_managers = Manager.order("users.login")
    end

    unless group_managers.empty?
         group_managers.each do |m|
           checked = false
           if(select_manager.include?(m.id))
             checked = true
           end
           data << {:type => @node_type,:label => m.login ,:labelStyle => 'icon-usr',:checked => checked,:id => m.id,:NodeType => NODE_TYP_USRN,:NodeId => m.id }
         end
    end

    unless data.empty?
      data = {:type => @node_type,:label => "Managers",:labelStyle => 'icon-grp',:expanded => true,:id => 0,:NodeType => NODE_TYP_GRPN,:NodeId => 0,:children => data }
    else
      data = nil
    end
    
    return data
    
  end

  #=========================================================#
  # Function

  def tree_node_type(node_type)

    case node_type
    when /text/:
        return 'Text'
    when /task/:
        return 'TaskNode'
    else
        return 'Text'
    end

  end

  def tree_with_agent(with_agent)

    if with_agent =~ /^false$/i
       return false
    else
       return true
    end

  end

  def enabled_tree_filter(filter)
                    
    if filter =~ /^false$/i or filter == 0
       return false
    else
       return true
    end

  end

  def tree_node_level()

    cate_type = []

    gcdts = GroupCategoryDisplayTree.all

    gcdts.each { |x| cate_type << {:id => x.id,:ct_id => x.group_category_type.id, :name => x.group_category_type.name, :parent_id => x.parent_id } if not x.parent_id }
    gcdts.length.times {
      f = cate_type.last
      gcdts.each { |x| cate_type << {:id => x.id,:ct_id => x.group_category_type.id, :name => x.group_category_type.name, :parent_id => x.parent_id } if x.parent_id and x.parent_id.to_i == f[:id].to_i }
    }

    data = []
    cate_type.each { |x| data << {:id => x[:ct_id],:name => x[:name]} }

    return data    

  end

  def display_groups(user)

    groups = []
    selected_groups = []
    owner = nil
    
    if user.is_a?(Integer)
      owner = User.where({:id => user}).first
    else
      owner = User.where({:login => user}).first
    end

    unless owner.nil?
  
      if (permission_by_name('tree_filter',owner.id)) and @use_filter
        owner_groups = Group.select('id').where({ :leader_id => owner.id })
        watch_groups = GroupMember.select('group_id').where({ :user_id => owner.id })
        selected_groups = (owner_groups.map { |g| g.id }).concat(watch_groups.map { |g| g.group_id })
        selected_groups = selected_groups.uniq
      else
        watch_groups = Group.select('id')
        selected_groups = watch_groups.map { |g| g.id }
      end

    end

    return selected_groups, owner

  end

  def groups_infomation(selected_group)

    grp_info = []

    unless selected_group.empty?
      
      sql = ""
      sql << " SELECT gc.group_id,g.name,gc.group_category_id,ga.group_category_type_id "
      sql << " FROM (((groups g JOIN group_categorizations gc ON g.id = group_id) JOIN group_categories ga ON gc.group_category_id = ga.id) JOIN group_category_types gt ON ga.group_category_type_id = gt.id) "
      sql << " WHERE g.id in (#{selected_group.join(',')}) "
      sql << " GROUP BY gc.group_id,g.name,gc.group_category_id,ga.group_category_type_id "

      grps = Group.find_by_sql(sql)

      grps_id = (grps.map { |g| g.group_id }).uniq
      grps_id.each do |g_id|
        tmp = {:id => g_id, :name => nil, :category => [], :ctype => []}
        grps.each do |x|
          if x.group_id == g_id
            tmp[:name] = x.name
            tmp[:category] << x.group_category_id
            tmp[:ctype] << x.group_category_type_id
          end
        end
        grp_info << tmp
      end

    end

    grp_info = grp_info.uniq
    
    return grp_info
    
  end

  def find_category_list(gct_id, gc_ids)  

    gcs = []

    $GRP_INFO.each do |x|

      i = x[:ctype].index(gct_id)
      unless i.nil?
        if gc_ids.empty?
          gcs << x[:category][i]
        else
          if gc_ids.to_set.subset?(x[:category].to_set)
            gcs << x[:category][i]
          end
        end
      end

    end
    gcs = gcs.uniq
    #STDERR.puts "----->#{gct_id} => #{gcs.join("|")}"
    gcs = GroupCategory.select('id,value as name').where("id in (#{gcs.join(',')})") unless gcs.empty?

    return gcs
    
  end

  def find_group_list(gc_ids)

    grp = []

    $GRP_INFO.each do |x|
      #STDERR.puts ">>>>>>>>#{gc_ids.sort.join('|')} == #{x[:category].sort.join('|')}"
      if (x[:category].sort).eql?(gc_ids.sort)
        grp << x[:id]
      end
    end
    
    grp = grp.uniq
    #STDERR.puts "G->#{grp.join("|")}"
    grp = Group.select('id,name').where("id in (#{grp.join(',')})") unless grp.empty?
    
    return grp
    
  end

  def find_agent_list(group_id)

    agents = []

    agents = Agent.select('id,login,display_name').alive.where({:group_id => group_id}).order('login') 
    
    unless agents.empty?
      agents = agents
    end

    return agents

  end
  
  def find_selected_agent(agents=[])
    
    tmp = {}
    
    agents = [] if agents.blank?
      
    if agents.include?('0')
      tmp['0'] = [0]
    end
      
    agents = User.select('id,group_id').where({ :id => agents })
    
    agents.each do |u|
      group_id = u.group_id.to_i.to_s
      tmp[group_id] = [] if tmp[group_id].nil?
      tmp[group_id] << u.id.to_i 
    end
    
    return tmp
    
  end
  
  #=========================================================#
  # End

  # == Tag Tree ============================================#

  def build_tag_tree

  end
  
end
