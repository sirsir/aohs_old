require 'base64'
require 'tempfile'
  
class ImageFile
  
  def self.base64_to_blob(data)
    extras_length = 'data:image/png;base64,'.length
    return Base64.decode64(data[extras_length..-1])
  end
  
  def self.base64_to_tempfile(data,name="imgprof")
    data_blob = base64_to_blob(data)
    tmpfile = Tempfile.new([name,'.png'])
    tmpfile.binmode
    tmpfile.write(data_blob)
    tmpfile.rewind
    tmpfile.close
    STDOUT.puts "Create new tempfile to #{tmpfile.path}"
    return tmpfile
  end

  def self.optimize_file(file_path)
    ofile = new(file_path)
    ofile.optimize_file
  end
  
  def initialize(path)
    @image_path = path 
  end
  
  def to_base64
    if image_ok?
      return base64_prefix + Base64.encode64(File.read(@image_path))
    end
    return nil
  end
  
  def optimize_file
    # for optimize file size for web
    if File.exists?(@image_path)
      if ['.jpg','.jpeg'].include?(File.extname(@image_path))
        cml = Cocaine::CommandLine.new(Settings.libexec.jpegoptim, Settings.libexec.jpegoptim_args)
        cml.run(file: @image_path)
      end
    end
  end
  
  private
  
  def image_ok?
    File.exists?(@image_path)  
  end
  
  def base64_prefix
    return "data:image/png;base64,"
  end
  
end