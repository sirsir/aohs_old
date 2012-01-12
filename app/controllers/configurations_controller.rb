class ConfigurationsController < ApplicationController

  layout "control_panel"
   
  before_filter :login_required, :except => [:export]
  before_filter :permission_require, :except => [:get_config,:export]

  def index

    @config = []

    @cfs = ConfigurationGroup.find(:all,
                              :conditions => {:configuration_type => 'C'},
                              :group => 'name')

    @config_type = ['Baseline','Groups','Users']
    @cfl = {}
    @cfl[:Baseline] = []
    @cfl[:Groups] = Group.find(:all,:select => 'id,name',:order => 'name')
    @cfl[:Users] = User.find(:all,:select => 'id,login as name,group_id',:order => 'login')

  end

  def new

    @configuration = Configuration.new()

  end

  def edit
    
  end

  def create

    @configuration = Configuration.new(params[:configuration])

    begin
      if @configuration.save
        log("Add","Configuration",true,"name:#{@configuration.variable}")
        redirect_to :controller => 'configurations', :action => 'index'    
      else
        log("Add","Configuration",false,"name:#{@configuration.variable},#{@configuration.errors.full_messages}")
        flash[:message] = @configuration.errors.full_messages
        render :action => 'new'
      end
    rescue => e
      log("Add","Configuration",false,"#{e.message}")
      flash[:message] = e.message
      render :action => 'new'
    end

  end

  def update

  end

  def delete

    @configuration = Configuration.find(params[:id])
    @configuration.destroy

    ConfigurationData.destroy_all(:configuration_id => params[:id])

    log("Delete","Configuration",true,"id:#{params[:id]}")

    redirect_to :controller => 'configurations', :type => 'system' ,:action => 'index'
    
  end

  def get_config

    result = []
    is_error = false
    cf_src = params[:q].strip

    cf_type, cf_sect, cf_subsect, cf_of = cf_src.split(".")
    
    if cf_type == "client"

      conditions = []
      conditions << "configuration_groups.configuration_type = 'C'"
      conditions << "configuration_groups.name = '#{cf_sect}'"

      cf1 = nil # default
      cf1 = Configuration.find(:all,
                              :include => [:configuration_group],
                              :conditions => conditions.join(' and '),
                              :order => 'configurations.variable')

      cfd_type = 0
      cfd_type_id = 0

      cf2 = nil # for cf edit
      cf3 = nil # baseline
      cf4 = nil # group

      conditions = []
 
      case cf_subsect
      when /^baseline/
          cfd_type = 0
          conditions << "(configuration_datas.config_type = 0 and configuration_datas.config_type_id is null)"
          cfd_type_id = 0        
      when /^groups/
          cfd_type = 1
          g = Group.find(:first,:conditions => {:name => cf_of})
		  unless g.nil?
			conditions << "((configuration_datas.config_type = 0 and configuration_datas.config_type_id is null) or (configuration_datas.config_type = 1 and configuration_datas.config_type_id = #{g.id}))"     
			cfd_type_id = g.id
		  else
			is_error = true
		  end
      when /^users/
          cfd_type = 2
          u = User.find(:first,:conditions => {:login => cf_of})     
		  unless u.nil?
			  if u.group_id.to_i > 0
				conditions << "((configuration_datas.config_type = 0 and configuration_datas.config_type_id is null) or (configuration_datas.config_type = 1 and configuration_datas.config_type_id = #{u.group_id.to_i}) or (configuration_datas.config_type = 2 and configuration_datas.config_type_id = #{u.id}))"
			  else
				conditions << "((configuration_datas.config_type = 0 and configuration_datas.config_type_id is null) or (configuration_datas.config_type = 2 and configuration_datas.config_type_id = #{u.id}))"            
			  end
			  cfd_type_id = u.id
		  else
		      is_error = true
		  end
      else #default
        
      end 
      
      conditions << "configuration_datas.configuration_id in (#{(cf1.map { |y| y.id }).join(',')})"
      if(cf_subsect != "default")
        cf2 = ConfigurationData.find(
                  :all, 
                  :conditions => conditions.join(' and '),
                  :order => 'configuration_datas.config_type asc')
      end
        
      cf1.each_with_index do |c,i|
          c_val = ""
          c_baseline = ""
          c_group = "&nbsp;"
        if cf2.nil?
          c_val = c.default_value
        else
          c_baseline = c.default_value
          c_group = c_baseline

          unless cf2.empty?
            cf2.each do |c2|
               if (c2.configuration_id == c.id)

                  case c2.config_type.to_i
                    when 0
                      c_baseline = c2.value
                      if c_baseline.blank?
                        c_baseline = c.default_value             
                      end
                      c_group = c_baseline
                    when 1
                      c_group = c2.value
                      if c_group.blank?
                        c_group = c_baseline
                      end
                    when 2
                      # ?
                    else
                      # ?
                  end
                  if (cfd_type.to_i == c2.config_type.to_i) and (cfd_type_id.to_i == c2.config_type_id.to_i)
                    c_val = c2.value
                  end
               else
                  # ?              
               end

            end

          end
          
        end

        result << {:no => i+1,
                   :id => c.id,
                   :name => c.variable,
                   :type => c.variable_type,
                   :default => (c.default_value.nil? ? "" : c.default_value),
                   :baseline => c_baseline,
                   :group => c_group,
                   :desc => c.description,
                   :val => c_val,
                   :cfd_type => cfd_type,
                   :cfd_type_id => cfd_type_id}
      end
      
    end

	result = [] if is_error
	
    render :text => result.reverse.to_json
    
  end

  def update_config

    cf_id = params[:conf].to_i
    cfd_type = params[:cfd_type].to_i
    cfd_type_id = params[:cfd_type_id].to_i

    cf_value = nil
    if params.has_key?(:val) and not params[:val].strip.empty?
      cf_value = params[:val].strip
      # if blank set to nil
      if cf_value == ""
        cf_value = nil
      end
    end  
    
    cf_src = params[:q].strip
    cf_type, cf_sect, cf_subsect, cf_of = cf_src.split(".")
		
    old_val = "NULL"
    new_val = "NULL"
    
    cf = Configuration.find(cf_id)
	
	case cf_type
	when /^client/
		begin
			  case cf_subsect
			  when /^baseline/
				cfd_type = 0
				if cf_value.nil?
				  cfd = ConfigurationData.delete_all({:configuration_id => cf_id, :config_type => cfd_type})
				else
				  cfd = ConfigurationData.find(:first,:conditions => {:configuration_id => cf_id, :config_type => cfd_type})
				  if cfd.nil?
					new_val = cf_value unless cf_value.nil?
					ncfd = {:configuration_id => cf_id, :config_type => cfd_type, :value => cf_value}
					cfd = ConfigurationData.new(ncfd).save
				  else
					old_val = cfd.value
					new_val = cf_value unless cf_value.nil?
					ucfd = {:value => cf_value}
					cfd = ConfigurationData.update(cfd.id,ucfd)
				  end
				end
			  when /^groups/
				cfd_type = 1
				if cf_value.nil?
				  cfd = ConfigurationData.delete_all({:configuration_id => cf_id, :config_type => cfd_type,:config_type_id => cfd_type_id})
				else
				  cfd = ConfigurationData.find(:first,:conditions => {:configuration_id => cf_id, :config_type => cfd_type,:config_type_id => cfd_type_id})
				  if cfd.nil?
					new_val = cf_value unless cf_value.nil?
					ncfd = {:configuration_id => cf_id, :config_type => cfd_type,:config_type_id => cfd_type_id, :value => cf_value}
					cfd = ConfigurationData.new(ncfd).save
				  else
					old_val = cfd.value
					new_val = cf_value unless cf_value.nil?
					ucfd = {:value => cf_value}
					cfd = ConfigurationData.update(cfd.id,ucfd)
				  end
				end		
			  when /^users/
				cfd_type = 2
				if cf_value.nil?
				  cfd = ConfigurationData.delete_all({:configuration_id => cf_id, :config_type => cfd_type,:config_type_id => cfd_type_id})
				else
				  cfd = ConfigurationData.find(:first,:conditions => {:configuration_id => cf_id, :config_type => cfd_type,:config_type_id => cfd_type_id})
				  if cfd.nil?
					new_val = cf_value unless cf_value.nil?
					ncfd = {:configuration_id => cf_id, :config_type => cfd_type,:config_type_id => cfd_type_id, :value => cf_value}
					cfd = ConfigurationData.new(ncfd).save
				  else
					old_val = cfd.value
					new_val = cf_value unless cf_value.nil?
					ucfd = {:value => cf_value}
					cfd = ConfigurationData.update(cfd.id,ucfd)
				  end
				end			
			  else #default
				cf = Configuration.find(:first,:conditions => {:id => cf_id})
				unless cf.nil?
				  old_val = cf.default_value unless cf.default_value.nil? 
				  new_val = cf_value unless cf_value.nil?     
				  Configuration.update(cf.id,{:default_value => cf_value})
				end
			  end 
			  
			  log("Update","Configuration",true,"#{params[:q]},:val[#{old_val}=>#{new_val}]")
			  
		rescue => e
			log("Update","Configuration",false,"#{params[:q]},#{e.message}")
		end
		
	when /^server/
		
	end

    render :text => true
    
  end

  def export
 
    # Example url
	# http://<root_url>/configurations.txt?user=<username>&group=<config_group>
	
    user_id = params[:user_id]
    user = params[:user]
    config_group = nil
	if params.has_key?(:group) and not params[:group].empty?
		config_group = params[:group]
	end
	
    conditions = ["configuration_groups.configuration_type = 'C'"]

    unless config_group.nil?
      conditions << "configuration_groups.name like '#{config_group}'"
    end

    cf1 = Configuration.find(:all,
                            :include => [:configuration_group],
                            :conditions => conditions.join(' and '),
                            :order => 'configuration_groups.name,configurations.variable')

    cfd_type = 2
    
    u = User.find(:first,:conditions => "id = '#{user_id}' or login = '#{user}'")
    
    cf_txt = []
    if not u.nil? and not cf1.empty?

      conditions = []
      if u.group_id.to_i > 0
        conditions << "((configuration_datas.config_type = 0 and configuration_datas.config_type_id is null) or (configuration_datas.config_type = 1 and configuration_datas.config_type_id = #{u.group_id.to_i}) or (configuration_datas.config_type = 2 and configuration_datas.config_type_id = #{u.id}))"
      else
        conditions << "((configuration_datas.config_type = 0 and configuration_datas.config_type_id is null) or (configuration_datas.config_type = 2 and configuration_datas.config_type_id = #{u.id}))"
      end

      cfd_type_id = u.id
      
      conditions << "configuration_datas.configuration_id in (#{(cf1.map { |y| y.id }).join(',')})"
      cf2 = ConfigurationData.find(:all,
                              :conditions => conditions.join(' and '),
                              :order => 'configuration_id,config_type desc')


      cf_group = nil
      cf1.each_with_index do |c,i|

        if not c.configuration_group.name == cf_group
          cf_txt << "[#{c.configuration_group.name}]"
          cf_group = c.configuration_group.name
        end

        c_val = c.default_value

        unless cf2.empty?
          cf2.each do |c2|
             if c2.configuration_id == c.id
               case c2.config_type.to_i
                 when 2
                    c_val = c2.value
                    break
                 when 1
                    c_val = c2.value
                    break
                 when 0
                    c_val = c2.value
                    break
               end

             end
          end
        end

        cf_txt << "#{c.variable}=#{c_val}"

      end
    end

    log("Export","Configuration",true,"user_id:#{params[:user_id]}")

    send_data cf_txt.join("\r\n"),{:filename => 'configuration.txt',:disposition => 'attachment',:type => 'plain/text'}
    
  end

end
