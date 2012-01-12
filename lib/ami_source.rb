
module AmiSource

  def import_data(op={}) 
    
    import_result = false
    result = {:error => 0,:found => 0, :new => 0, :update => 0, :delete => 0,:skip => 0, :dup => 0, :msg => []}
      
    directory = File.join(Rails.public_path,'temp')

    # check zip file

    fname = File.join(directory,'data_upload.zip')
    if File.exist?(fname)
      cmd = "unzip -o #{fname} -d #{directory}"
      success = system(cmd)
      STDOUT.puts "Unzip source : #{fname} - #{success}"
    else
      STDOUT.puts "Unzip source : #{fname} - false"  
    end

    # check source files

    src_files = {
            :users => 'users.csv',
            :groups => 'groups.csv',
            :customers => 'customers.csv',
            :keywords => 'keywords.csv',
            :dnis_agents => 'dnis_agents.csv'}

    # ===============================================================================

    ActiveRecord::Base.transaction do

      src_raw_data = {}
      src_files.each_pair do |key,value|

        if File.exist?(File.join(directory,value.to_s))

            result[:file] = key
              
            cols = []

            STDERR.puts " Open source file : #{File.join(directory,value.to_s)}"

            # replace mode
            if op[:replace] == true
              case key
              when :dnis_agents
                DnisAgent.delete_all
              else
                # option wrong
              end
            end
            
            # insert or update
			line_no = 0;
            File.open(File.join(directory,value.to_s)).each do |line|
                
			  line_no += 1
			  
              next if line.nil?
              line = line.strip.gsub('"','').to_s
              next if line.empty?
              ##next if line.blank?
                
              if cols.empty?
                cols = line.split(",")
              else
                
                result[:found] += 1
                  
                case key
                  when :users

                    # get users

                    u = {}
                      
                    u[:cti_agent_id], u[:id_card], u[:login], u[:display_name], u[:email], u[:group_name], u[:gender], u[:role_name], u[:status], u[:expired_date] = line.split(',',9)
                    
                    u[:password] = Aohs::DEFAULT_PASSWORD_NEW
                      
                    u[:role_id], u[:role_type] = map_role_name(u[:role_name])
                    u[:group_id] = map_group_name(u[:group_name])
                    u[:password] = map_password_blank(u[:login],u[:password])
                    u[:cti_agent_id] = check_cti_agent_id(u[:cti_agent_id])
                    
					# user_type 
					u[:role_type] = verify_role_and_usr_type(u[:login],u[:role_type])

                    # save
                    kact = "SKIP"
                    case u[:role_type]
                      when :agent
                        x = Agent.find(:first,:conditions => {:login => u[:login]})
                        if x.nil?
                          xn = {:login => u[:login],:display_name => u[:display_name],:email => u[:email],:sex => u[:gender], :role_id => u[:role_id], :group_id => u[:group_id],:password => u[:password],:password_confirmation => u[:password],:cti_agent_id => u[:cti_agent_id],:id_card => u[:id_card], :expired_date => u[:expired_date]}
                          xn = Agent.new(xn)
                          if xn.save
							  xn.update_attribute(:state,'active')
							  kact = "INSERT"
							  result[:new] += 1		
						  else
							  result[:error] += 1
							  result[:msg] << "Line #{line_no}:#{xn.errors.full_messages}"	
						  end
                        else
                          if op[:update] == true
                            xu = {:display_name => u[:display_name],:email => u[:email],:sex => u[:gender], :role_id => u[:role_id], :group_id => u[:group_id],:state => 'active',:cti_agent_id => u[:cti_agent_id],:id_card => u[:id_card], :expired_date => u[:expired_date]}
                            rs = Agent.update(x.id,xu)
                            if(rs)
                              kact = "UPDATE"
                              result[:update] += 1
                            else
                              kact = "UPDATE FAILED"
                              result[:skip] += 1
                            end
                          else
                            result[:dup] += 1
                          end
                        end
                      when :manager
                        u[:group_id] = 0
                        x = Manager.find(:first,:conditions => {:login => u[:login]})
                        if x.nil?
                          xn = {:login => u[:login],:display_name => u[:display_name],:email => u[:email],:sex => u[:gender], :role_id => u[:role_id], :group_id => u[:group_id],:password => u[:password],:password_confirmation => u[:password],:cti_agent_id => u[:cti_agent_id],:id_card => u[:id_card], :expired_date => u[:expired_date]}
                          xn = Manager.new(xn)
                          if xn.save
							xn.update_attribute(:state,'active')
							kact = "INSERT"
							result[:new] += 1
						  else
							result[:error] += 1
							result[:msg] << "Line #{line_no}:#{xn.errors.full_messages}"
						  end
                        else
                          if op[:update] == true
                            # skip upd ,:password => u[:password],:password_confirmation => u[:password]
                            xu = {:display_name => u[:display_name],:sex => u[:gender],:email => u[:email], :role_id => u[:role_id], :group_id => u[:group_id],:state => 'active',:cti_agent_id => u[:cti_agent_id],:id_card => u[:id_card], :expired_date => u[:expired_date]}
                            rs = Manager.update(x.id,xu)
                            if(rs)
                              kact = "UPDATE"
                              result[:update] += 1
                            else
                              kact = "UPDATE FAILED"
                              result[:skip] += 1
                            end
                          else
                            result[:dup] += 1
                          end
                        end
                    else
                      result[:error] += 1
                      result[:msg] << "Unknown role"  
                    end

                    STDOUT.puts " -#{kact} : User/#{u[:role_type]}->#{u[:login]}"
                    STDOUT.puts ""
                  
                  when :groups

                    # get group
                  
                  when :customers

                    # get

                    c = {}
                    c[:name], c[:phones] = line.strip.split(',',2)
                    c[:phones] = c[:phones].split(',')

                    # name
                    customer_id = 0
                    cust = Customers.find(:first,:conditions => {:customer_name => c[:name]})
                    if cust.nil?
                      xn = {:customer_name => c[:name]}
                      xn = Customers.new(xn)
                      xn.save
                      cust = Customers.find(:first,:conditions => {:customer_name => c[:name]})
                      customer_id = cust.id
                      result[:new] += 1
                    else
                      customer_id = cust.id
                      if op[:update] == true
                        xc = {:customer_name => c[:name]}
                        xc = Customers.update(cust.id,xc)
                        result[:update] += 1
                      else
                        result[:skip] += 1
                      end
                    end
                    
                    # phones
                    unless c[:phones].blank?
                      c[:phones].each do |phone|
                        phone = phone.strip
                        p = CustomerNumbers.find(:first,:conditions => {:customer_id => customer_id,:number => phone})
                        if p.nil?
                          p = {:customer_id => customer_id,:number => phone}
                          p = CustomerNumbers.new(p).save
                        end
                      end
                    end

                when :keywords

                    # get

                    k = {}
                    k[:keyword_name], k[:keyword_type], k[:keyword_group] = line.split(',',3)

                    STDOUT.puts "Keyword : #{k[:keyword_name]} - #{k[:keyword_type]}"
                    # save

                    keyword = Keyword.find(:first,:conditions => {:name => k[:keyword_name]})
                    if keyword.nil?
                      xk = {:name => k[:keyword_name], :keyword_type => map_keyword_type(k[:keyword_type])}
                      xk = Keyword.new(xk)
                      xk.save
                      keyword = Keyword.find(:first,:conditions => {:name => k[:keyword_name]})
                      result[:new] += 1  
                    else
                      if op[:update] == true
                        # not use
                        result[:update] = 0
                      else
                        ##result[:skip] += 1
                        result[:dup] += 1  
                      end
                    end

                    unless keyword.nil?
                      if not k[:keyword_group].nil? and not k[:keyword_group].empty?
                        STDOUT.puts "Kgroup: #{k[:keyword_group]}"
                        keyword_group = KeywordGroup.find(:first,:conditions => {:name => k[:keyword_group]})
                        if keyword_group.nil?
                          xkg = {:name => k[:keyword_group]}
                          xkg = KeywordGroup.new(xkg)
                          xkg.save
                          keyword_group = KeywordGroup.find(:first,:conditions => {:name => k[:keyword_group]})
                        else
                          if op[:update] == true
                            # not use
                          end
                        end
                        
                        kgm = KeywordGroupMap.find(:first,:conditions => {:keyword_id => keyword.id,:keyword_group_id => keyword_group.id})
                        if kgm.nil?
                          kgm = {:keyword_id => keyword.id,:keyword_group_id => keyword_group.id}
                          kgm = KeywordGroupMap.new(kgm).save
                        end
                      end

                    end

                when :dnis_agents
                      
                  k = {}
                  k[:dnis], k[:ctilogin], k[:team] = line.split(',',3)
                                      
                  STDOUT.puts "DinsAgent : #{k[:dnis]}, #{k[:ctilogin]}, #{k[:team]}"
                  
                  today = Time.new.strftime("%Y-%m-%d %H:%M:%S")
                  
                  dnis_agent = DnisAgent.find(:first,:conditions => {:ctilogin => k[:ctilogin]})
                  if dnis_agent.nil?
                    k[:created_at] = today
                    dnis_agent = DnisAgent.new(k)
                    dnis_agent.save
                  else
                    if op[:update] == true
                      k[:updated_at] = today
                      dnis_agent = DnisAgent.update(dnis_agent.id,k)
                    end
                  end 
                  
                end # end when

              end

            end # end r file

        end

      end

      import_result = true

    end # end transaction
    
    return import_result, result
    
  end # def

  def map_role_name(role_name)

    role_id = nil
    role_type = nil
     
    if (role_name.strip.downcase == "agent") or (role_name.strip.downcase == "none")
      role_name = "Agent"
      role_type = :agent
    else
      role_type = :manager
    end
    
    unless role_name.blank?
      role = Role.find(:first, :conditions => {:name => role_name})
      unless role.blank?
        role_id = role.id
      else
        role_type = :unknown
      end
    else
      role_type = :unknown
    end

    STDOUT.puts " -GET: Role->#{role_name}/#{role_id}"

    return role_id, role_type
    
  end

	def verify_role_and_usr_type(login_name,role_type)
		new_role_type = role_type
		u_tmp = User.find(:first,:conditions => {:login => login_name})
		unless u_tmp.nil?
			if u_tmp.type.to_s == "Manager"
				new_role_type = :manager
			elsif u_tmp.type.to_s == "Agent"
				new_role_type = :agent						    
			end
		end
		return new_role_type
	end
					
  def map_group_name(group_name)

    group_id = nil

    unless group_name.blank?
      group = Group.find(:first,:conditions => {:name => group_name})
      unless group.blank?
        group_id = group.id
        STDOUT.puts " -GET: Group->#{group_name}/#{group_id}"
      else
        xg = {:name => group_name}
        group = Group.new(xg)
        group.save
        group_id = Group.find(:first,:conditions => {:name => group_name}).id
        STDOUT.puts " -INSERT: Group->#{group_name}/#{group_id}"
      end
    end
    
    return group_id

  end

  def map_group_category_id(categories)

    group_categories_id = []

    unless categories.blank?
      categories.each_pair do |gt,g|
        gct = GroupCategoryType.find(:first,:conditions => {:name => gt.to_s})
        gc = GroupCategory.find(:first,:conditions => {:group_categroy_type => gct.id, :value => g})
        group_categories_id << gc.id
      end
    end
    
    return group_categories_id
    
  end

  def map_manager_name(leader)

    manager_id = nil

    x = Manager.find(:first,:conditions => {:name => u[:login]})
    if x.nil?
      xn = {:login => u[:login],:display_name => u[:login],:sex => nil, :role_id => nil, :group_id => nil,:password => "password",:password_confirmation => "password"}
      xn = Manager.new(xn)
      xn.save
      x = Manager.find(:first,:conditions => {:name => u[:login]})
    end
    manager_id = x.id
    
    return manager_id
    
  end
    
  def map_password_blank(login,password)

    if password.strip.blank?
      return login
    else
      return password.strip
    end

  end

  def map_keyword_type(keyword_type)

    if not keyword_type.nil? and keyword_type.is_a?(String)
      keyword_type = keyword_type.downcase
    end

    case keyword_type
      when 'm','must'
        return 'm'
      when 'n','ng'
        return 'n'
      when 'a','action'
        return 'a'
      else
        return nil
    end

  end

  def check_cti_agent_id(cti_agent_id)
    if cti_agent_id.nil?
      return nil
    else
      return cti_agent_id
    end
  end

  #
  # Export
  #

  def export_data(op={})

    key = op[:table].downcase.to_sym
    begin
      key2 = op[:model].to_sym
    rescue
      key2 = nil
    end

    csv_src = ""
    fname = "unknown-export.csv"

    case key
      when :users

        default_password = "aohsweb"

        usr_model = []
        case key2
          when :agents
            usr_model << Agent
            fname = "users-agents.csv"
          when :managers
            usr_model << Manager
            fname = "users-managers.csv"
          else
            usr_model = [Agent,Manager]
            fname = "users.csv"
        end
        cols = ['agent_id','citizen_id','username','full_name','e-mail','group','sex','role','status','expire_date']
        data = []
        usr_model.each do |md|
          usrs = md.find(:all,:order => 'login')
          unless usrs.blank?
             usrs.each do |usr|
               data << ([
                 usr.cti_agent_id,
                 usr.id_card,
                 usr.login,
                 usr.display_name,
                 usr.email,
                 check_group_name(usr),
                 usr.sex2,
                 check_role_name(usr),
                 usr.state,
               usr.expired_date].map { |x| "\"#{x}\""}).join(',')
               #data << [usr.login,default_password,usr.display_name,usr.sex2,check_role_name(usr),check_group_name(usr),usr.cti_agent_id,usr.id_card].join(',')
             end
          end
        end
        csv_src = chang_to_csv(cols,data)
      
      when :customers

          fname = "customers.csv"
          
          customers = Customers.find(:all,:include => :customer_numbers, :order => "customer_name")

          cols = ['customer_name','phone_number1','phone_number2']
          data = []

          unless customers.empty?
            customers.each do |c|
              phones = c.customer_numbers.empty? ? "" : (c.customer_numbers.map { |p| "\"#{p.number.strip}\"" }).sort.join(",")
              data << [c.customer_name,phones].join(",")
            end
          end
          csv_src = chang_to_csv(cols,data)
      
      when :keywords

          fname = "keywords.csv"

          keywords = Keyword.find_by_sql("select k.name,k.keyword_type,kg.name as keyword_group from keywords k left join (keyword_group_maps km join keyword_groups kg on km.keyword_group_id = kg.id) on k.id = km.keyword_id order by k.name")

          cols = ['keyword_name','keyword_type','keyword_group']
          data = []

          unless keywords.empty?
            keywords.each do |k|
              kg_name = k.keyword_group.blank? ? "" : k.keyword_group
              data << [k.name,k.display_keyword_type,kg_name].join(",")
            end
          end
          csv_src = chang_to_csv(cols,data)
      
      when :dnis_agents
        
          fname = "dnis_agents.csv"
          
          dnis_agents = DnisAgent.find(:all,:order => 'dnis,ctilogin')
          
          cols = ['DNIS','CTI Login','Team']
          data = []
            
          unless dnis_agents.empty?
            dnis_agents.each do |d|
              data << ([d.dnis,d.ctilogin,d.team].map { |g| "\"#{g}\"" }).join(',')
            end
          end
          csv_src = chang_to_csv(cols,data)

      else

        # error

    end

    return csv_src, "#{get_export_dtime}_#{fname}"
    
  end

  def check_group_name(usr)

    if usr.group_id.to_i <= 0
      return ""
    else
      return usr.group.name
    end
  end

  def check_role_name(usr)

    if usr.role.nil?
      return "None"
    else
      return usr.role.name
    end
    
  end
  
  def chang_to_csv(cols,data)

    txt_src = []

    txt_src << cols.join(",")

    unless data.blank?
      txt_src = txt_src.concat(data)
      data = nil
    end

    return txt_src.join("\r\n")
    
  end

  def get_export_dtime
    return Time.now.strftime("%Y%m%d_%H%M")  
  end

end # module