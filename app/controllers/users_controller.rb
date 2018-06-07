class UsersController < ApplicationController
  
  before_action :authenticate_user!
  
  protect_from_forgery except: [:upload_image]

  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage
    @users = User.ransack(conditions_params).result.includes(:user_atl_attrs)
    @users = User.ransack_ext(@users,params)
    @users = @users.order_by(order_params).page(page).per(per)
  end
  
  def new
    @user = User.new
    @group_member = GroupMember.new
  end
  
  def create
    @user = User.new(user_params)
    @group_member = GroupMember.new(group_params)
    if @user.do_active(true) and @user.save
      save_group_member
      @user.update_attrs(custom_attribute_params)
      db_log(@user, :new)
      flash_notice(@user, :new)
      redirect_to action: "index", id: @user.id
    else
      render action: "new"
    end
  end
  
  def edit
  
    @user = User.find_id(user_id)
    @is_suspended = (@user.suspend? or @user.was_deleted?)
    
    unless @user.nil?
      @group_member = @user.group_member
      @group_member_hist = @user.group_member_histories.order(created_date: :desc).all
      @sites = @user.user_attributes.attr_name(:locations).first.attr_val.split("|").map { |lc| lc.to_i } rescue []
    else
      redirect_to action: "index"
    end
  
  end
  
  def update
    
    @user = User.find_id(user_id)
    @group_member = @user.group_member
    @group_member = @user.new_group_member if @group_member.nil?
    @is_suspended = (@user.suspend? or @user.was_deleted?)
    @sites = @user.user_attributes.attr_name(:locations).first.attr_val.split("|").map { |lc| lc.to_i } rescue []
    
    from_confirm_page = params[:confirm_page] == "yes"
    
    # got parameter to reset password
    if params.has_key?(:reset_password) and params[:reset_password] == "yes"
      @user.reset_default_password
    else
      if authentication_params[:password].present? and not authentication_params[:password].empty?
        @user.set_password_with_parm(authentication_params)
      end
    end
    
    if @user.update_attributes(user_params)
      
      @group_member.attributes = group_params
      save_group_member
      @user.update_attrs(custom_attribute_params)
      db_log(@user, :update)
      flash_notice(@user, :update)
      
      if from_confirm_page
        redirect_to controller: 'home', action: 'index'
      else
        redirect_to action: "edit"
      end
    else
      if from_confirm_page
        render action: "confirm"
      else
        render action: "edit"
      end
    end
    
  end
  
  def update_attr
    
    user = User.find_id(user_id)
    unless user.nil?
      user.update_attr(attr_params)
      db_log(user, :update)      
    end
    
    render text: "ok"

  end
  
  def delete
    
    result = ""
    @user = User.find_id(user_id)
    
    unless @user.nil?
      if @user.do_delete and @user.save
        db_log(@user, :delete)
        flash_notice(@user, :delete)
        result = "deleted"
      end
    end
    
    render text: result
  
  end
  
  def destroy
    
    delete
  
  end
  
  def undelete
  
    result = ""
    @user = User.find_id(user_id)
    
    unless @user.nil?
      if @user.do_undelete and @user.save      
        db_log(@user, :update)
        flash_notice(@user, :update)
        result = "undeleted"
      end
    end
    
    render text: result
  
  end
  
  def show
    
    redirect_to index_with_filter_url
    
  end
  
  def export
    
    filetype = params[:filetype]
    exported_file = ImportExport.export_to_file(:user, { conditions: conditions_params })
    converted_file = FileConversion.docs_convert(filetype, exported_file, skip_err: true)
    
    logger.info "Export users data to #{converted_file} as #{filetype}"
    
    cookies['fileDownload'] = true
    send_file converted_file
    
  end
  
  def import
    
    do_step = import_step
    err_message = ""
    
    case do_step
    when :verifydata
      if params.has_key?(:ca)
        converted_file = get_import_file_cache
        if converted_file.nil?
          err_message = "File conversion failed"
        end
        render json: { error: err_message }  
      end
      
    when :import
      if params.has_key?(:ca)
        converted_file = get_import_file_cache
        require_replace = params[:update_replace]
        if not converted_file.nil?
          result = ImportExport.import_from_file(:user, converted_file, { update_if_exist: require_replace })
        else
          err_message = "File conversion failed"
        end
        render json: { results: result }  
      end
    else
      
      @step = do_step
    end
  
  end
  
  def logout
  
    redirect_to destroy_user_session_path

  end
  
  def profile
    @user = current_user
    @logs = OperationLog.access_history(@user.login).order("created_at desc").limit(20)
    @group_members = @user.group_members
    
    if params[:dialog] == "change_password"
      render :password_expiry, layout: 'blank'
    else
      render layout: 'application'
    end
  end
  
  def password
    get_user
    if (not @user.nil?) and (not authentication_params[:password].empty?)
      @user.set_password_with_parm(authentication_params)
      if @user.save
        bypass_sign_in(@user)
        flash_notice(@user, :change_password)
      else
        flash[:error] = @user.errors.full_messages.join(", ")
      end
    end
    redirect_to action: "profile", target: 'change_password', dialog: params[:dialog]
  end
  
  def card
    @user = User.find_id(user_id)
    render layout: 'blank'
  end
  
  def list
    max_select = 100
    select = [:id, :login, :full_name_en, :full_name_th]
    
    users = User.select(select).not_deleted.order(login: :asc).limit(max_select)
    if params.has_key?(:q)
      users = users.full_name_cont(params[:q])
    end
  
    data = users.all.map { |u| {
        id: u.id,
        name: u.display_name,
        text: u.display_name }
    }
    
    # unknown agent
    if params.has_key?(:unknown)
      ounk = {
        id: 0,
        name: '(unknown)',
        text: '(unknown)'
      }
      data = data.insert(0,ounk)
    end

    render json: data  
  end
  
  def mailer
    
    max_select = 100
    select = [:id, :email, :full_name_en, :full_name_th]
    
    users = User.select(select).not_deleted.have_email.order("email").limit(max_select)
    if params.has_key?(:q)
      q = params[:q]
      users = users.where("email LIKE ?","#{q}%")
    end

    data  = users.all.map { |u| {
        id: u.id,
        text: u.mail_name }
    }
    
    render json: data
    
  end
  
  def upload_image
    
    user = User.where(id: user_id).first
    avatar = user.avatar || UserPicture.new({ user_id: user.id })
    
    f_uri = params[:data_uri]
    f_file = params[:file]
    d_type = params[:type]
    
    auf = AvatarUploader.new
    if params.has_key?(:data_uri)
      image_file = ImageFile.base64_to_tempfile(f_uri)
      auf.cache! image_file
    elsif params.has_key?(:file)
      auf.cache! f_file
      ImageFile.optimize_file(auf.current_path)
    end
    
    case d_type
    when 'temp'
      img_url = auf.url
      img = ImageFile.new(auf.path)
      render json: { uploaded_url: img_url, srcbase64: img.to_base64 }
    else
      Rails.logger.info "Upload File: #{auf.inspect}"
      avatar.store_file(auf)
      avatar.save
      render json: { result: true } 
    end
    
  end
  
  def avatar
    
    # get binary date (blob) of picture from database
    # if not exist show default
    
    f_avatar = 'app/assets/images/avatar-default.png'
    u_avatar = UserPicture.where(user_id: params[:id]).first
    
    unless u_avatar.nil?
      send_data u_avatar.image_data_bin, type: u_avatar.content_type
    else
      send_data File.read(File.join(Rails.root,f_avatar))
    end

  end
  
  def get_group
    
    group = nil
    usr = User.select(:id).where(id: user_id).first
    unless usr.nil?
      group = {
        id: usr.group_id,
        name: usr.group_name
      }
    end
    
    render json: group
    
  end
  
  def unlock
    
    result = { unlock: nil }
    
    usr = User.where(id: user_id).first
    if not usr.nil?
      usr.unlock_access!
      result[:unlock] = "success" 
    end
    
    render json: result
    
  end

  def unlock_info
  
  end
  
  def confirm
    @user = User.where(id: current_user.id).first
    render layout: 'blank_with_header'
  end
  
  def notify
    @user = User.where(id: user_id).first
  end
  
  private
  
  def get_user
    @user = User.where(id: user_id).first
  end
  
  def user_id
    params[:id].to_i
  end
  
  def user_params
    params.require(:user).permit(
            :login,
            :employee_id,
            :citizen_id,
            :full_name_en,
            :full_name_th,
            :email,
            :sex,
            :joined_date,
            :dob,
            :title_id,
            :state,
            :dsr_profile_id,
            :notes,
            :atl_code,
            :role_id)
  end
  
  def attr_params
    return {
      user_id: params[:id],
      attr_type: params[:attr_id],
      attr_val: params[:attr_value]
    }
  end
  
  def authentication_params
    # params for change password.
    # required old password and new pasword
    if params[:user].has_key?(:old_password)
      params.require(:user).permit(:old_password, :password, :password_confirmation)
    else
      params.require(:user).permit(:password, :password_confirmation)
    end
  end
  
  def save_group_member
    
    @group_member.set_as_member
    @group_member.user_id = @user.id
    @group_member.save
    
    # remove existings member
    gm = {
      user_id:  @user.id,
      group_id: @group_member.group_id
    }
    group_member = GroupMember.only_follower.where(gm).first
    unless group_member.nil?
      group_member.delete
    end
    
  end
  
  def import_step
    
    case params[:step].to_s
    when "verify", "verifydata"
      return params[:step].to_sym
    else
      return :import
    end
    
  end
  
  def get_import_file_cache
    
    dfu = DocumentFileUploader.new
    dfu.retrieve_from_cache!(params[:ca])
    converted_file = FileConversion.docs_convert(:csv, dfu.file.path)
    
    return converted_file
  
  end
  
  def group_params
    return { user_id: @user.id, group_id: (params[:user][:group_member].nil? ? nil : params[:user][:group_member][:group_id]) }
  end

  def order_params
    get_order_by(:login)
  end
  
  def custom_attribute_params
    atrs = []
    atrs_params = params["custom_attribute"]
    unless atrs_params.nil?
      atrs_params.each do |atr_id,atr_val|
        atrs << { id: atr_id, value: atr_val }
      end
    end
    return atrs
  end
  
  def conditions_params
    
    conds = {
      login_cont:       get_param(:login),
      full_name_cont:   get_param(:name),
      employee_id_eq:   get_param(:employee_id),
      citizen_id_eq:    get_param(:citizen_id),
      group_member_in:  [get_param(:group_id)],
      role_id_eq:       get_param(:role_id),
      state_eq:         get_param(:state),
      email_cont:       get_param(:email),
      performance_group_eq: get_param(:performance_group_id),
      section_eq:       get_param(:section_id)
    }
    
    conds = conds.remove_blank!
    
    unless logged_as_admin?
      # allow only admin to see deleted users
      conds[:state_not_eq] = STATE_DELETE
    else
      unless conds[:state_eq].present?
        conds[:state_not_eq] = STATE_DELETE
      end
    end
    return conds
    
  end

end
