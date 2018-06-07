require 'fileutils'
require 'securerandom'

module WorkingDir

  class HouseKeeping
    
    def self.cleanup_working_dir
      paths = [
        Settings.server.directory.tmp,
        Settings.server.directory.audio_data
      ]
      paths.each do |path|
        if Dir.exists?(path)
          cleanup_target_dir(path)
        end
      end
    end
    
    private
    
    def self.cleanup_target_dir(path)  
      exts = ["wav", "mp3", "spx", "svg", "info", "tmp", "log", "xls", "xlsx", "csv", "txt", "dat"].join(",")
      Dir.glob(File.join(path,"*.{#{exts}}")).each do |f|
        file_age_hr = (Time.now - File.mtime(f))/(3600.0)
        if file_age_hr >= Settings.server.temp.file_age_hr
          File.delete(f)
        end
      end
    end
    
    # end class
  end

  class WorkingFolder
    
    MIN_FILE_AGES = 30
    
    def initialize(path)
      
      @dir_path = path
      @errors   = []
      
      prepare_directory
      
    end
    
    def path
      return @dir_path
    end
    
    def is_exist?
      return (File.exists?(@dir_path) and File.directory?(@dir_path) and (can_write?))
    end
    
    def can_write?      
      return File.writable?(@dir_path)
    end
    
    def size_bytes
      return nil
    end

    def errors
      return @errors
    end    

    def cleanup_files(file_age=MIN_FILE_AGES)      
      if file_age > MIN_FILE_AGES
        @file_age = file_age.to_i
        remove_file_in_dir(@dir_path)
      end
    end
    
    private
    
    def prepare_directory  
      return (is_exist? or create_directory)
    end
    
    def create_directory
      begin
        result_mk = FileUtils.mkdir_p(@dir_path, mode: 0775)
        if not is_exist?
          @errors << "Cannot create or access #{@dir_path}"
        end
      rescue => e
        @errors << "Create #{@dir_path} was incomplete."
      end
      return is_exist?
    end
    
    def dir_split(path)
      return path.split(File::SEPARATOR)
    end
    
    def remove_file_in_dir(dir)
      file_pattern = "*.{svg,dat,txt,log,mp3,wav,spx,csv,xlsx,xls,pdf}"
      Dir.glob(File.join(dir,file_pattern)).each do |f|
        if File.directory?(f)
          remove_file_in_dir(f)
          #Dir.rmdir(f)
        else
          file_age_days = (Time.now - File.ctime(f))/(3600 * 24)
          if file_age_days >= @file_age
            #File.delete(f)
          end
        end
      end
    end

    # end class
  end
  
  #
  # ----
  #
  
  def self.public_directory_path(subdirs=nil)
    pub_path = File.join(Settings.server.directory.public)
    unless subdirs.nil?
      pub_path = File.join(pub_path,subdirs)
    end
    wkf = WorkingFolder.new(pub_path)
    return wkf.path
  end
  
  def self.file_rename(fpath, new_fname)
    fpath_new = File.join(File.dirname(fpath),new_fname)
    if FileUtils.mv(fpath, fpath_new)
      return fpath_new
    end
    return fpath
  end
    
  def self.prepare_dirs
    list_dir.each do |dir|
      next if dir.to_s.length <= 1
      begin
        xdir = WorkingFolder.new(dir)
        STDOUT.puts "#{dir}, #{xdir.errors.join(", ")}" unless xdir.errors.empty?
      rescue => e
        STDERR.puts "create directory failed, [#{dir}]"
      end
    end
  end
  
  def self.tmpdir_exist?
    tmp_dir = WorkingFolder.new(Settings.server.directory.tmp)
    return tmp_dir.is_exist?
  end
  
  def self.make_tmpdir(basedir, prefix=false)
    if prefix == true
      basedir = [basedir,SecureRandom.hex(4)].join("_")
    end
    return make_dir(basedir)
  end  
  
  def self.make_dir(dir_path)
    wdir = WorkingDir::WorkingFolder.new(dir_path)
    return dir_path
  end
  
  def self.cleanup_files
    tmp_dir = WorkingFolder.new(Settings.server.directory.tmp)
    tmp_dir.cleanup
  end
  
  def self.clean_cache
  
  end
  
  private
  
  def self.list_dir
    base_dir = Settings.server.directory
    return [
      base_dir.home,
      base_dir.tmp,
      base_dir.spool,
      base_dir.libexec,
      base_dir.backup,
      base_dir.public,
      base_dir.call_export,
      base_dir.audio_data,
      base_dir.log,
      base_dir.export_log
    ]
  end
  
  # end module
end