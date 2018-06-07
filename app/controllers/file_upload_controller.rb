class FileUploadController < ApplicationController
  
  skip_before_filter :verify_authenticity_token, only: [:upload]
  before_action :authenticate_user!
  
  def upload
    dfu = uploaded_file
    msgs = [
      "file-name=#{dfu.filename}",
      "cache-name=#{dfu.cache_name}",
      "file-type=#{dfu.content_type}",
      "size="
    ]
    
    result = {
      errors: [],  
      file_name: dfu.filename,
      cache_name: dfu.cache_name,
      file_type: dfu.content_type
    }
    
    Rails.logger.info "File has been uploaded, #{msgs.join(",")}"
    
    render json: result
  end
  
  private
  
  def uploaded_file
    dfu = DocumentFileUploader.new
    dfu.cache! uploadedfile_params
    return dfu
  end
  
  def uploadedfile_params
    params[:uploadedfile]
  end
  
end
