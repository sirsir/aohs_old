require 'csv'

class ExportBase
  
  def initialize(opts={})
    
    @conds = opts[:conditions] || {}
    
  end
  
  def export_to_csv
    
    recs      = get_data
    csvfile   = get_filename
    file_mode = 'w'
    
    CSV.open(csvfile, file_mode) do |cf|
      cf << headers
      unless recs.empty?
        recs.each do |r|
          cf << fields(r)
        end
      end
    end
    
    return output_file(csvfile)
    
  end
  
  private
  
  def output_file(f_file)
    
    if File.exists?(f_file)
      return f_file
    end
    
    return nil
   
  end
  
  def get_filename
    
    output_dir = Settings.server.directory.tmp
    fname      = [file_name,Settings.filetype.csv].join('.')

    return File.join(output_dir,fname)
  
  end

end