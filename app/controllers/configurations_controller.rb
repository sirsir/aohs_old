class ConfigurationsController < ApplicationController

  before_action :authenticate_user!, except: [:configurations]
  
  layout LAYOUT_MAINTENANCE
  
  def index
    
    @conf_groups = ConfigurationGroup.order(name: :asc).all
    @conf_group  = ConfigurationGroup.where(name: config_name).first
    @programs = []
    
    if @conf_group.nil?
      @conf_group = @conf_groups.first
    end
    
    @conf_for = ConfigurationTree::NODE_TYPES.first
    @configurations = @conf_group.configurations.order(variable: :asc).all
    
    case config_name
    when "program"
      @programs = ProgramInfo.order(name: :asc).all
    when "location_info"
      sites_old = []
      sites_ids = VoiceLog.select("DISTINCT site_id").days_ago(90).all.map { |v| v.site_id.to_i }
      @location_infos = LocationInfo.order(id: :asc).all.to_a
      sites_ids.each do |site_id|
        @location_infos.each do |lc|
          if lc.id == site_id
            lc.available == true
            sites_old << lc.id
            break
          end
        end
      end
      sites_ids.delete_if { |x| sites_old.include?(x) } 
      sites_ids.each do |site_id|
        lc = LocationInfo.new({ id: site_id, code_name: "Unknown-#{site_id}"})
        lc.available
        @location_infos << lc 
      end
    when "display_tables"
      @display_tables = DisplayColumnTable.table_list.all
      if not params[:table].present? or params[:table].empty?
        @display_columns = DisplayColumnTable.by_table(@display_tables.first.table_name).only_visible
      else
        @display_columns = DisplayColumnTable.by_table(params[:table]).only_visible
      end
    when "group_member_type"
      @member_types = GroupMemberType.all_types
    end
    
  end

  def update
  
    conf_group = ConfigurationGroup.where(id: params[:id]).first
    conf_for   = params[:type]
    
    if not conf_group.nil? and not conf_for.nil?
      confs = params[:conf]
      
      # tree
      conf_tree = ConfigurationTree.where(node_type: conf_for, configuration_group_id: conf_group.id).first
      if conf_tree.nil?
        conf_tree = ConfigurationTree.new({node_id: 0, node_type: conf_for, configuration_group_id: conf_group.id})
        conf_tree.save
      end
      confs.each do |conf_id, val|
        confd = ConfigurationDetail.where(configuration_tree_id: conf_tree.id, configuration_id: conf_id).first
        if confd.nil?
          confd = ConfigurationDetail.new({configuration_tree_id: conf_tree.id, configuration_id: conf_id})
        else
          if val.to_s.empty?
            confd.delete
            next
          end
        end
        confd.conf_value = val.to_s
        confd.save
      end
    end
  
    redirect_to index_with_filter_url
    
  end

  def configurations
    
    file_format = params[:format] || "txt"
    config_name = params[:name] || "amiwatcher"
    login       = params[:user]
    remote_ip   = request.remote_ip
    
    @conf_for   = ConfigurationTree::NODE_TYPES.first
    @conf       = ConfigurationGroup.where({name: config_name}).first
    unless @conf.nil?
      @confs = @conf.configurations.order(variable: :asc).all
    else
      @confs = []
    end
    
    if @conf.nil?
      render text: "", layout: false, status: 503
    else
      data = render_to_string layout: false
      send_data data, filename: "configuration.txt", type: 'plain/text'
    end

  end
  
  def update_programs
  
    data = params[:data]
    updated_id = []
    
    data.each_value do |d|
      
      id = d["id"].to_i
      title = d["title"]
      bg_c = d["bg"]
      
      if id > 0
        pg = ProgramInfo.where(id: id).first
      else
        pg = ProgramInfo.where(name: title).first
      end
      if pg.nil?
        pg = ProgramInfo.new
      end
      
      pg.name = title
      pg.bg_color = bg_c
      pg.save
      
      updated_id << pg.id
      
    end
    
    unless updated_id.empty?
      ProgramInfo.where.not(id: updated_id).delete_all
    end
    
    render json: true
    
  end

  def update_program_list
  
    procs = UserActivityLog.proc_list.with_in_days(45).all
    unless procs.empty?
      procs.each do |proc|
        next if proc.proc_name.blank?
        next if proc.proc_exec_name.blank?
        cond = {
          proc_name: proc.proc_exec_name
        }
        pg = ProgramInfo.where(cond).first
        if pg.nil?
          pg = ProgramInfo.new(cond)
          pg.name = proc.proc_name
          pg.save
        end
      end
    end
    
    render json: true
    
  end
  
  def update_module
    
    title = params[:name]
    prev_status = params[:status]
    
    mod = nil
    APP_MODULES.each do |l|
      if l[:title] == title
        mod = l
        break
      end
    end
    
    unless mod.nil?
      flag_enable = (prev_status == "disabled")
      Privilege.module_disable_or_enable(mod[:list], flag_enable)
    else
      if title == "reset" and prev_status == "reset"
        Privilege.disabled_function.update_all(flag: "")
      end
    end
    
    Rails.cache.delete_matched(/^(privilege_of_)(.+)/)
    
    render json: true
  end

  def update_locations
    
    data = params[:data]
    data.each_value do |v|
      lc_id = v["id"]
      location = LocationInfo.where(id: lc_id).first
      if location.nil?
        location = LocationInfo.new(id: lc_id, code_name: v["name"], name: v["name"])
      end
      location.code_name = v["name"]
      location.name = v["name"]
      location.save!
    end
    render json: true
  end

  def update_display_columns
    
    data = params[:data]
    no = 1
    data.each_value do |v|
      cl = DisplayColumnTable.where(id: v['id']).first
      unless cl.nil?
        if v["enable"] == "true"
          cl.enable
        else
          cl.disable
        end
        if v["search_enable"] == "true"
          cl.enable_search
        else
          cl.disable_search
        end
        cl.order_no = no * 10
        cl.save
        no += 1
      end      
    end
    
    render json: true
  end
  
  private
  
  def config_name
    
    if params[:name].present?
      params[:name].to_s
    else
      params[:name] = "amiwatcher"
      params[:name]
    end
    
  end
  
end
