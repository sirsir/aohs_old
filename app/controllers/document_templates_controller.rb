class DocumentTemplatesController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage
    @templates = DocumentTemplate.ransack(conditions_params).result
    @templates = @templates.not_deleted.order_by(order_params).page(page).per(per)
  end
  
  def new
    @doc_template = DocumentTemplate.new
  end
  
  def create
    @doc_template = DocumentTemplate.new(template_params)
    begin
      @doc_template.store_file_to_db(uploaded_file)
    rescue => e
      @doc_template.errors.add(:file_data, :invalid, message: e.message)
    end
    if @doc_template.errors.empty? and @doc_template.save
      @doc_template.set_mapped_fields_from_file
      @doc_template.save
      db_log(@doc_template, :new)
      flash_notice(@doc_template, :new)
      redirect_to action: :edit, id: @doc_template.id
    else
      render action: :new
    end
  end
  
  def edit
    get_template
  end

  def update
    get_template
    begin
      if params[:document_template].has_key?(:file_data)
        @doc_template.store_file_to_db(uploaded_file)
      end
    rescue => e
      @doc_template.errors.add(:file_data, :invalid, message: e.message)
    end
    @doc_template.attributes = template_params
    if @doc_template.errors.empty? and @doc_template.save
      @doc_template.set_mapped_fields_from_file
      @doc_template.save
      db_log(@doc_template, :update)
      flash_notice(@doc_template, :update)
      redirect_to action: :edit, id: @doc_template.id
    else
      render action: :edit
    end
  end

  def delete
    get_template
    @doc_template.do_delete
    @doc_template.save
    db_log(@doc_template, :delete)
    flash_notice(@doc_template, :delete)
    render text: "deleted"
  end
  
  def destroy
    delete
  end
  
  def download_preview
    get_template
    template_file = @doc_template.file_template
    output_file = FileConversion.docs_convert(:pdf, template_file.filepath)
    cookies['fileDownload'] = true
    send_data File.read(output_file), filename: "#{@doc_template.file_name}.pdf"
  end
  
  private
  
  def order_params  
    get_order_by(:title)
  end
  
  def conditions_params
    conds = {
      title_cont: get_param(:title)
    }
    conds = conds.remove_blank!
    return conds    
  end

  def template_id
    params[:id]
  end
  
  def template_params
    params.require(:document_template).permit(:title, :description)  
  end
  
  def uploaded_file
    # save uploaded template file to temp
    tmpfile = DocumentTemplateUploader.new
    tmpfile.cache! params[:document_template][:file_data]
    return tmpfile
  end

  def get_template
    @doc_template = DocumentTemplate.where(id: template_id).first
  end

end
