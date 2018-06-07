class EvaluationDocAttachmentsController < ApplicationController

  before_action :authenticate_user!
  layout 'blank'
  
  def new
    begin
      get_template
      get_attachment
    rescue => e
      Rails.logger.error "Not found document template, #{e.message}"
      redirect_to action: 'not_found'
    end
  end

  def create
    get_template
    get_attachment    
    @evaluation_doc.doc_data = template_params
    @evaluation_doc.save
    db_log(@evaluation_doc, :update)
    flash_notice(@evaluation_doc, :update)
    redirect_to action: :edit, id: @evaluation_doc.id, template_id: template_id, log_id: evaluation_log_id, dlfile: params[:dlfile]
  end

  def edit
    get_template
    get_attachment
  end
  
  def update
    get_template
    get_attachment    
    @evaluation_doc.doc_data = template_params
    @evaluation_doc.save
    db_log(@evaluation_doc, :update)
    flash_notice(@evaluation_doc, :update)
    redirect_to action: :edit, id: @evaluation_doc.id, template_id: template_id, log_id: evaluation_log_id, dlfile: params[:dlfile]
  end

  def delete
    # replace with action doc_delete
  end
  
  def doc_delete
    @evaluation_doc = EvaluationDocAttachment.where(id: params[:id]).first
    if not @evaluation_doc.nil?
      @evaluation_doc.do_delete
      @evaluation_doc.save
    end
    render json: { deleted: true }    
  end

  def download
    get_template
    get_attachment
    
    if params[:preview_template] == "yes"
      mapped_result = nil
    else
      mapped_result = @evaluation_doc.mapped_fields_for_render
    end
    outfile_path = @template.render_to_file(mapped_result)
    
    cookies['fileDownload'] = true    
    respond_to do |format|
      format.xlsx do
        send_data File.read(outfile_path), filename: @evaluation_doc.filename(@template.file_name) + ".xlsx"
      end
      format.pdf do
        outfile = FileConversion.docs_convert(:pdf, outfile_path)
        send_data File.read(outfile), filename: @evaluation_doc.filename(@template.file_name) + ".pdf"
      end
    end
  end
  
  def list
    # only status
    @evaluation_doc = EvaluationDocAttachment.not_deleted.where({ evaluation_log_id: evaluation_log_id, document_template_id: template_id }).first
    if @evaluation_doc.nil?
      render json: {
        id: 0
      }
    else
      render json: {
        id: @evaluation_doc.id
      }
    end
  end
  
  private
  
  def template_id
    params[:template_id] || params[:document_template_id]
  end
  
  def evaluation_log_id
    params[:log_id] || params[:evaluation_log_id]
  end
  
  def get_template
    @template = DocumentTemplate.where(id: template_id).first
  end
  
  def get_attachment
    @evaluation_doc = EvaluationDocAttachment.not_deleted.where({ evaluation_log_id: evaluation_log_id, document_template_id: template_id }).first
    if @evaluation_doc.nil?
      @evaluation_doc = EvaluationDocAttachment.new(create_params)
    end
    @evaluation_doc.do_init({ template: @template })
  end
  
  def create_params
    return {
      document_template_id: template_id,
      evaluation_log_id: evaluation_log_id
    }
  end
  
  def template_params
    data = params[:cst]
    mapped_data = []
    data.each do |k,v|
      mapped_data << {
        name: "[#{k}]",
        value: v
      }
    end
    return mapped_data
  end
  
  # end class
end
