require "digest"

module AppUtils
  
  DBNAME = "checksum.db"
  
  class SourceFileChecker
    
    def self.scan_and_update  
      scs = new
      scs.scan
      scs.update
    end
    
    def self.scan_and_compare
      scs = new
      scs.scan
      scs.compare
    end
    
    def initialize  
      @files = []
    end
    
    def scan
      root_dir = Rails.root
      scan_dirs = ['app', 'bin', 'config', 'db', 'lib', 'test', 'vendor']
      scan_dirs.each do |dir|    
        list = list_of_file(File.join(root_dir, dir))
        @files = @files.concat(list)
      end
    end
    
    def update
      fout = File.join(Rails.root,'db', DBNAME)
      File.open(fout,'w') do |fo|
        @files.each do |f|
          fo.puts [
            f[:ext],
            f[:name],
            f[:size],
            f[:mtime],
            f[:digest]
          ].join("|")
        end
      end
    end
    
    def compare
      # [TODO]
    end
    
    private

    def list_of_file(dir)
      allfiles = []
      founds = Dir.glob(File.join(dir,"*"))
      founds.sort.each do |f|
        if File.directory?(f)
          allfiles.concat(list_of_file(f))
        else
          allfiles << get_file_info(f)
        end
      end
      return allfiles
    end
    
    def get_file_info(f)  
      return {
        size: File.size(f),
        digest: Digest::MD5.hexdigest(File.read(f)),
        mtime: File.mtime(f).strftime("%Y%m%dT%H%M%S"),
        ext: File.extname(f),
        name: f.gsub("#{Rails.root}","RAILS_ROOT"),
      }
    end
    
  end
  
  # end module
end
