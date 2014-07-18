namespace :application do

  desc 'Setup configurations'
  task :permission => :setup do

    Rake::Task['application:permission:remove'].invoke
    Rake::Task['application:permission:create'].invoke

  end

  namespace :permission do

     desc 'Create permission'
     task :create => :setup do
        create_role
        create_privilege
        create_permission
        create_admin_user
     end

     desc 'Remove permission'
     task :remove => :setup do
        remove_permission
     end

     desc 'Update privilege'
     task :update => :setup do
        create_admin_user
        create_privilege
     end

  end

end

def create_permission

  STDERR.puts "--> Creating permissions ..."

  # role
  begin

    STDERR.puts "--> Creating permission for administrator ..."

    role_id = Role.find(:first,:conditions => {:name => 'Administrator'}).id

    privileges = Privilege.find(:all)
    privileges.each do |priv|
        Permission.new(:role_id => role_id,:privilege_id => priv.id).save!
    end
    
    STDERR.puts "--> Creating privilege and permissions are successfully."
  rescue
    STDERR.puts "--> Creating privilege and permissions are failed."
  end

end

def remove_permission

  STDERR.puts "--> Removing permissions ..."

  begin
    Role.delete_all()
    Privilege.delete_all()
    Permission.delete_all()
    STDERR.puts "--> Removing role,privilege and permission are successfully."
  rescue => e
    STDERR.puts "--> Removing permission are failed. [#{e.message}]"
  end

end

def create_privilege

  STDERR.puts "--> Creating privilege ... "

  # portal
  privileges_group1 = [
    {:name => 'calls_browser',  :desc => 'Calls Browser',:open => Aohs::MOD_CALL_BROWSER },      
    {:name => 'report-today',   :desc => 'Show report today (Home)'},
    {:name => 'voice_logs',     :desc => 'Access agents calls'},
    {:name => 'customers',      :desc => 'Access customers calls'},
    {:name => 'customers-upd',  :desc => 'Manage customers information'},
    {:name => 'favorites',      :desc => 'Access call tags'},
    {:name => 'favorites-upd',  :desc => 'Manage call tags'},
    {:name => 'voice_logs-exp', :desc => 'Export/Print calls report'},
    {:name => 'bookmarks-upd',  :desc => 'Manage call bookmarks'},
    {:name => 'callskeyw-upd',  :desc => 'Manage call keywords', :open => Aohs::MOD_KEYWORDS},
    {:name => 'voice_logs-download', :desc => 'Export voice file'},
    {:name => 'statistics',     :desc => 'View agents report'},
    {:name => 'statistics-exp', :desc => 'Export/Print agents calls\'s report'},
    {:name => 'keywords',       :desc => 'View keywords report', :open => Aohs::MOD_KEYWORDS },
    {:name => 'keywords-upd',   :desc => 'Manage keywords and keyword group', :open => Aohs::MOD_KEYWORDS },
    {:name => 'keywords-exp',   :desc => 'Export/Print keywords report', :open => Aohs::MOD_KEYWORDS },
    {:name => 'data-keywords',  :desc => 'Import/Export keywords data', :open => Aohs::MOD_KEYWORDS },
    {:name => 'tree_filter',    :desc => 'Enable Groups/Agents filter'},
    {:name => 'tree_mycall',    :desc => 'Enable searching my call'}
 ]
 # control panel
 privileges_group2 = [  
    {:name => 'control_panel',  :desc => 'Access control panel'},
    {:name => 'managers',       :desc => 'View managers list'},
    {:name => 'managers-upd',   :desc => 'Manage managers'},
    {:name => 'managers-access',:desc => 'Manage Access control of manager(s)'},
    {:name => 'agents',         :desc => 'View agents list'},
    {:name => 'agents-upd',     :desc => 'Manage agents'},
    {:name => 'data-users',     :desc => 'Import/Export users data'},
    {:name => 'groups',         :desc => 'View groups list'},
    {:name => 'groups-upd',     :desc => 'Manage groups'},
    {:name => 'group_categories',         :desc => 'View group categories and catogory types list'},
    {:name => 'group_categories-upd',     :desc => 'Manage group categories'},
    {:name => 'group_category_types-upd', :desc => 'Manage category type of groups'},
    {:name => 'call_tags',      :desc => 'View call tags'},
    {:name => 'call_tags-upd',  :desc => 'Manage call tags'},
    {:name => 'extension',      :desc => 'View phone extensions'},
    {:name => 'extension-upd',  :desc => 'Manage phone extensions'},
    {:name => 'dnis_agents',    :desc => 'Manage DnisAgent'},
    {:name => 'customer',       :desc => 'Manage customers'},
    {:name => 'log',            :desc => 'View logs'},
	  {:name => 'computer_log',   :desc => 'Computer Log'},
    {:name => 'event',          :desc => 'View event' , :open => false },
    {:name => 'configurations', :desc => 'View configurations system'},
	  {:name => 'configurations-upd',        :desc => 'Manage configurations system'},
    {:name => 'permission',     :desc => 'Manage privileges and permission'},
    {:name => 'role-upd',       :desc => 'Manage roles'}
  ]

  privileges_group_names = ['Top Panel','Control Panel']
  
  application_name = "AOHS"
  
  order_no = 0
  [privileges_group1,privileges_group2].each_with_index do |p,i|
    p.each do |x|
      if Privilege.find(:first,:conditions => {:name => x[:name]}).nil?
        if(x[:open] != false)
          Privilege.new(:name => x[:name],:description => x[:desc],:order_no => order_no,:display_group => privileges_group_names[i], :application => application_name).save
        end
      else
        upd = Privilege.find(:first,:conditions => {:name => x[:name]})
        if(x[:open] == false)
          upd.destroy
        else
          upd = Privilege.update(upd.id,{:name => x[:name],:description => x[:desc],:order_no => order_no,:display_group => privileges_group_names[i], :application => application_name})        
        end
      end
      order_no += 1
    end
  end

  STDERR.puts "--> Creating privilege are successfully."
  
end

def create_role

  STDERR.puts "--> Creating role ..."

  roles = [
    { :name => 'Administrator', :desc => 'System administrator' },
    { :name => 'Agent', :desc => 'None user or operator' },
    { :name => 'Assistant Manager', :desc => 'Assistant' },
    { :name => 'Manager', :desc => 'Manaager' },
    { :name => 'Chief', :desc => 'Chief' },
    { :name => 'Supervisor', :desc => 'Supervisor' },
    { :name => 'Staff', :desc => 'Staff' }
  ]

  roles.each do |x|
     next if Role.exists?(:name => x[:name])
     Role.new(:name => x[:name], :description => x[:desc]).save!
  end

  STDERR.puts "--> Creating role are successfully."

end

def create_admin_user
    AmiUser.create_admin_account
end