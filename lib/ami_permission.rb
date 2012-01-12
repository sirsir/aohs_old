
module AmiPermission

  def permission_require
      
    if not have_permission?
      #flash[:error] = "Sorry, you have been denied access to this page. Please contact web administrator."
      redirect_to :controller => 'top_panel', :action => 'denied'
    end

  end
 
  def list_of_controllers

    controller_list = []

    ary_controllers = Dir.new("#{Rails.root}/app/controllers").entries
    ary_controllers.each do |ctl|
      if ctl =~ /_controller/
        controller_list << ctl.camelize.gsub(".rb","")
      end
    end
    ary_controllers = nil
    
    return controller_list

  end

  def get_permission_name(str_controller_name,str_action_name)

    key = nil
    key1 = str_controller_name
    key2 = nil
  
    details = {
              :agents => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :call_browser => {
                      'map'    => :calls_browser },
              :calls_browser => {
                      'view'   => ['index'],
                      'manage' => []},
              :call_tags => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :configurations => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :control_panel => {
                      'view'   => ['index'],
                      'manage' => []},
              :computer_log => {
                      'view'   => ['index']},
              :customers => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :customer => {
                      'view'   => ['index','new','create','edit','update','delete']},
              :dnis_agents => {
                      'view' => ['index','new','create','edit','update','delete','show','list']},
              :event => {
                      'view'   => ['index'],
                      'manage' => []},
              :extension => {
                      'view'   => ['index'],
                      'manage' => ['new','new_did','edit','edit_did','create','add_dids','update','update_did','delete','delete_did','export','csv_import']},              
              :favorites => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :groups => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :group_categories => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :group_category => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},                        
              :group_category_types => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete','destroy']},
              :keywords => {
                      'view'   => ['index'],
                      'manage' => ['create','edit','update','new','delete'],
                      'output' => ['print','export']},
              :log => {
                      'view'   => ['index'],
                      'manage' => []},
              :managers => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :permission => {
                      'view'   => ['index'],
                      'manage' => ['update']},
              :role  => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete']},
              :statistics => {
                      'view'   => ['index'],
                      'manage' => []},
              :tag => {
                      'view'   => ['index'],
                      'manage' => ['new','create','edit','update','delete','manage']},
              :tag_groups => {
                      'map'    => :call_tags },
              :top_panel => {
                      'view'   => ['index'],
                      'manage' => []},
              :voice_logs => {
                      'view'   => ['index'],
                      'manage' => [],
                      'output' => ['print','export'],
                      'download' =>['download']}
              }

    unless details[str_controller_name.to_sym].nil?

      ctl = details[str_controller_name.to_sym]
      if not ctl['map'].nil?
        key1 = ctl['map']
        ctl = details[ctl['map']]
      end

      if not ctl['view'].blank? and ctl['view'].include?(str_action_name)
        key2 = nil
      elsif not ctl['manage'].blank? and ctl['manage'].include?(str_action_name)
        key2 = 'upd'
      elsif not ctl['output'].blank? and ctl['output'].include?(str_action_name)
        key2 = 'exp'
      elsif not ctl['download'].blank? and ctl['download'].include?(str_action_name)
        key2 = 'download' 
      end

      unless key2.nil?
        key = "#{key1}-#{key2}"
      else
        key = key1
      end

    else
      key = ""
    end

    return key

  end

  def have_permission?(str_controller_name=nil,str_action_name=nil,privilege_name=nil,user_id=nil)

    privilege_key_name = nil

    login_user = nil

    unless user_id.nil?
      login_user = User.where({ :id => user_id }).first
    else
      login_user = current_user
    end

    if privilege_name.nil?
      str_current_controller = str_controller_name.nil? ? params[:controller] : str_controller_name
      str_current_action = str_action_name.nil? ? params[:action] : str_action_name
      privilege_key_name = get_permission_name(str_current_controller,str_current_action)
    else
      privilege_key_name = privilege_name
    end

    bln_permission = false

    unless login_user.nil?

      usr_role_id = login_user.role_id

      strsql = ""
      strsql << " select count(a.privilege_id) as priv_count "
      strsql << " from permissions a join privileges b on a.privilege_id = b.id "
      strsql << " where a.role_id = #{usr_role_id} and b.name like '#{privilege_key_name}' "

      result = Permission.find_by_sql(strsql)

      found_cnt = 0
      unless result.blank?
        found_cnt = result.first.priv_count
        if found_cnt.to_i > 0
          bln_permission = true
        else
          bln_permission = false
        end
      else
        bln_permission = true
      end

    else
      bln_permission = false
    end
    
    STDOUT.puts "[Permission - #{usr_role_id}] #{privilege_key_name} => #{bln_permission}"
    
    return bln_permission

  end

  def link_permission_require(str_controller_name,str_action_name)

    bln_display_link = true

    if not str_controller_name.nil? and not str_action_name.nil?
      bln_display_link = have_permission?(str_controller_name,str_action_name)
    end

    return bln_display_link

  end

  def permission_by_name(privilege_name="",user_id=nil)

    bln_permission = have_permission?(nil,nil,privilege_name,user_id)

    return bln_permission

  end

end