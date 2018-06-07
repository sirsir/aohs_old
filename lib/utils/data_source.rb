module AppUtils
  
  class DataSource
    
    def self.load(src_name)
      return new(src_name)
    end
    
    def initialize(src_name)
      # initial
      @src_name = src_name
      @src_data = nil
      # load data from source file
      load_source
    end
    
    def data
      return @src_data
    end
    
    private

    def load_source
      src_fpath = source_file_name
      if not src_fpath.nil? and File.exists?(src_fpath)
        @src_data = select_source_data(JSON.parse(File.read(src_fpath)))
      end
    end
    
    def select_source_data(data)
      # select data from soure by
      # - customer/site
      unless data.nil?
        src_key = Settings.site.codename
        unless data[src_key].nil?
          return data[src_key]
        end 
      end
      return data
    end
    
    def source_file_name
      dir = File.join(Rails.root,'lib','data')
      case @src_name
      when :user_attributes, "user_attributes"
        return File.join(dir,'data_attribute.user.json')
      end
      return nil
    end
    
    # end class
  end
  
  # end module
end