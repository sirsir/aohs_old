require 'digest'

class DocumentTemplate < ActiveRecord::Base

  has_paper_trail :ignore => [:file_data]
  serialize :mapped_fields, JSON
  
  strip_attributes  allow_empty: true,
                    collapse_spaces: true,
                    except: [:file_data]
                    
  has_many    :evaluation_doc_attachments
  
  validates :title,
              presence: true,
              length: {
                minimum: 3,
                maximum: 150
              }
              
  validates :file_data,
              presence: true

  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)  
  }
  
  scope :order_by, ->(p) {  
    incs = []
    includes(incs).order(resolve_column_name(p))
  }
  
  scope :order_by_default, ->{
    order(:title)  
  }
  
  def file_type_name
    return self.file_type.gsub(".","")
  end

  def deleted?
    self.flag == DB_DELETED_FLAG
  end
  
  def store_file_to_db(f_uploader)
    # store file data and attributes to fields
    # file format, filename, size, and md5
    self.file_type = File.extname(f_uploader.filename)
    self.file_path = File.basename(f_uploader.filename)
    self.file_size = f_uploader.file.size
    self.file_data = File.open(f_uploader.current_path,'rb').read
    begin
      #self.file_hash = Digest::MD5.hexdigest(File.read(f_uploader.current_path))
    rescue => e
      #self.file_hash = "error_md5_digest"
    end
    Rails.logger.info "DocumentTemplate, stored file from #{f_uploader.current_path} to field. MD5 is #{self.file_hash}"
  end

  def do_delete
    self.flag = DB_DELETED_FLAG
  end
  
  def file_template
    initial_cache_file
    return @doc_template
  end
  
  def display_fields
    dsp_fields = []
    template = file_template
    return template.mapped_fields  
  end
  
  def file_name
    fname = FileName.sanitize(self.title) rescue File.basename(self.file_path) 
    return fname
  end

  def set_mapped_fields_from_file
    dtemplate = file_template
    self.mapped_fields = dtemplate.mapped_fields
  end

  def render_to_file(data=nil)
    template = file_template
    output_fpath = template.write_to_file(get_tmp_filename, data)
    return output_fpath
  end
  
  private
  
  ## cache file ##
  
  def initial_cache_file
    store_cache_to_file unless cache_loaded?
    @doc_template = DocTemplateReader.new(cache_filepath)
  end
  
  def store_cache_to_file
    wf = WorkingDir.make_dir(cache_directory)
    @cache_file = File.new(cache_filepath,"wb")
    @cache_file.write self.file_data
    @cache_file.close
    Rails.logger.info "Loaded document template for '#{self.title}/#{self.id}' to #{cache_filepath}, size=#{File.size(cache_filepath)}"
  end
  
  def cache_loaded?
    defined? @cache_file and File.exists?(cache_filepath)
  end
  
  def cache_filename
    "#{self.id}#{self.file_type}"
  end  
  
  def cache_filepath
    File.join(cache_directory, cache_filename)
  end
  
  def cache_directory
    File.join(Rails.root, "tmp", "cache", "doc_template")
  end  
  
  ## cache file ##

  def get_tmp_filename
    fname = "dct_#{self.id}.xlsx"
    return File.join(Settings.server.directory.tmp,fname)
  end
  
  def self.resolve_column_name(str)    
    unless str.empty?

    end    
    return str
  end
  
  # end class
end
