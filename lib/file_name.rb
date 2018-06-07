require 'securerandom'
require 'facets/file/sanitize'

module FileName
  
  def self.current_dt
    return Time.now.strftime("%Y%m%dT%H%M")
  end
  
  def self.current_d
    return Time.now.strftime("%Y%m%d")
  end
  
  def self.rand_name(filename)
    # to rename downloaded file to avoid duplicate name
    # pattern: <some-string>_<original_filename>.<ext>
    return File.join(File.dirname(filename),[SecureRandom.hex(2),File.basename(filename)].join("_"))
  end
  
  def self.sanitize(fname)
    # remove forbidden characters from string
    begin
      return replace_file_name(fname.gsub(/[<>|\\\/\:\;\!\&\?]/,""))
    rescue => e
      return replace_file_name(File.sanitize(fname))
    end
  end
  
  private
  
  def self.replace_file_name(fname)
    return fname.gsub(" ","_")
  end
  
end
