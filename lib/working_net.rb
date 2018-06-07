require 'net/http'

module WorkingNet
  
  HTTP_CODE_SUCCESS = 400
  
  def self.url_exist?(url_s)
    
    # List of HTTP status code
    # 1xx  Info
    # 2xx  Success
    # 3xx  Redirection
    # 4xx  Client Error
    # 5xx  Server Error
    
    begin
      url = URI.parse(url_s)
      req = Net::HTTP.new(url.host, url.port)
      res = req.request_head(url.path)
      return success_response?(res.code)
    rescue Errno::ENOENT
      return false
    end

  end
  
  def self.file_download(url, target_dir=nil)
  
    dest_dir = output_directory(target_dir)

    f_uri = URI.parse(url)
    fname = File.join(dest_dir, File.basename(f_uri.path))
    fname = FileName.rand_name(fname)
    
    if do_download?(url, fname) and File.exists?(fname)
      Rails.logger.info "Download #{url} to #{fname} completed"
    else
      Rails.logger.error "Download #{url} to #{fname} was error"
      fname = nil     
    end
    
    return fname
  
  end

  protected
  
  def self.success_response?(response_code)
    return (response_code.to_i < HTTP_CODE_SUCCESS)
  end
  
  def self.output_directory(out_dir)
    
    # if target directory not define or not exist,
    # save to temporary by default
    
    dest_dir = Settings.server.directory.tmp
    if not out_dir.nil? and Dir.exist?(out_dir)
      dest_dir = out_dir
    else
      dest_dir = WorkingDir.make_dir(File.join(dest_dir, "downloads"))
    end
    
    return dest_dir
  
  end
  
  def self.do_download?(url,out_file) 
    begin
      cml = Cocaine::CommandLine.new(Settings.libexec.wget, Settings.libexec.wget_args)
      cml.run(url: url, output_fname: out_file)
      return true
    rescue => e
      Rails.logger.error "Failed to download #{url} - #{e.message}"
      return false
    end
  end
  
end
