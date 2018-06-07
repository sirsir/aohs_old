class PhoneExtensionsController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage
    @extensions = Extension.search(conditions_params).result
    @extensions = @extensions.order_by(order_params).page(page).per(per)
  end
  
  def new
    @extension = Extension.new(@extparams)
    @extension.do_build
  end
  
  def create
    @extparams = extension_params
    @extension = Extension.new(@extparams)
    if @extension.save
      db_log(@extension, :new)
      flash_notice(@extension, :new)
      redirect_to action: "edit", id: @extension.id
    else
      render action: "new"
    end
  end
  
  def edit
    get_extension
    @extension.do_build
  end
  
  def update
    get_extension
    if @extension.update_attributes(extension_params)
      db_log(@extension, :update)
      flash_notice(@extension, :update)
      redirect_to action: "edit"
    else
      render action: "edit"
    end
  end
  
  def delete
    get_extension
    result  = ""
    if @extension.delete
      db_log(@extension, :delete)
      flash_notice(@user, :delete)
      result = "deleted"
    end
    render text: result
  end
  
  def destroy
    delete
  end
  
  def watcher
    log_date = nil
    if params.has_key?(:log_date) and not params[:log_date].empty?
      log_date = Date.parse(params[:log_date])
    end
    rp = WatcherReport.new(log_date)
    @watcher_logs = rp.result
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
          result = ImportExport.import_from_file(:extension, converted_file, { update_if_exist: require_replace })
        else
          err_message = "File conversion failed"
        end
        render json: { results: result }  
      end
    else
      
      @step = do_step
    end
  end
  
  def export
    
  end
  
  private

  def extension_id
    return params[:id]
  end
  
  def get_extension
    @extension = Extension.where(id: extension_id).first
  end
  
  def extension_params
    params.require(:extension).permit(
        :number,
        :desc,
        :user_id,
        :location_id,
        dids_attributes: [:id, :number],
        computer_info_attributes: [:id, :computer_name, :ip_address])
  end

  def update_params
    params[:extension].require(:computer_info).permit(
        :computer_name,
        :ip_address)
  end
  
  def order_params
    get_order_by(:number)
  end

  def conditions_params
    conds = {
      number_cont: get_param(:extension),
      computer_name_like: get_param(:computer_name),
      computer_ip_like: get_param(:computer_ip),
      dids_cont: get_param(:dids)
    }
    conds.remove_blank!
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

end
