require 'net/sftp'
require 'fileutils'

class SftpClient
    
  def initialize(config)
    
    #
    # config parameters
    # host: <host>
    # port: <port>
    # user: <username>
    # password: <password>
    # 
    
    @config = config
    
  end
  
  def get_files(target_path, dest_path, opts={})
        
    files = []
    
    #
    # find files which is match options
    #
    
    log :info, "trying connect to sftp #{@config[:user]}:#{@config[:host]}"
    log :info, "download options: #{opts.inspect}"
    
    Net::SFTP.start(@config[:host], @config[:user], sftp_options) do |sftp|
      unless opts[:file_patterns].blank?
        entries = []
        opts[:file_patterns].each do |pat|
          entries.concat(sftp.dir.glob(target_path, "**/#{pat}").sort_by(&:name))
        end
      else
        entries = sftp.dir.glob(target_path, "**/*.*").sort_by(&:name)
      end
      entries.each do |entry|
        next if entry.name =~ /^(\.)/
        fa = entry.attributes
        fl = {
          path: entry.name,
          size: fa.size,
          mdate: Time.at(fa.mtime),
          type: File.extname(entry.name)
        }
        if select_to_download?(fl, opts)
          files << fl
        end
      end
    end
    
    log :info ,"found #{files.length} files"
    
    #
    # download selected files
    #
    
    unless files.empty?
      Net::SFTP.start(@config[:host], @config[:user], sftp_options) do |sftp|
        log :info, "trying to download, output_path=#{dest_path}"
        files.each do |file|
          begin
            dest_dir = File.join(dest_path, File.dirname(file[:path]))
            unless File.exists?(dest_dir)
              FileUtils.mkdir_p(dest_dir)
            end
            srcfile = File.join(target_path, file[:path])
            outfile = File.join(dest_path, file[:path])
            sftp.download!(srcfile, outfile)
            file[:outpath] = outfile
            log :info, "downloaded ... #{file[:path]}"
          rescue => e
            log :error, "download failed ... #{file[:path]}, #{e.message}"
          end
        end
      end
    end
    
    # return selected files
    return files
  end
    
  private
  
  def sftp_options
    opts = {
      verify_host_key: false,
      non_interactive: true
    }
    
    unless @config[:password].empty?
      opts[:password] = @config[:password]
    end
    
    return opts
  end
  
  def select_to_download?(file, opts={})
    
    if file[:size] <= 0
      return false
    end

    # check file types
    unless opts[:file_type].nil?
      case true
      when opts[:file_type].is_a?(Array)
        unless opts[:file_type].include?(file[:type])
          return false
        end
      when opts[:file_type].is_a?(String)
        unless opts[:file_type] == file[:type]
          return false
        end
      end
    end
    
    # check file age
    unless opts[:before_time].nil?
      if opts[:before_time] > file[:mdate]
        return false
      end
    end
    unless opts[:after_time].nil?
      if opts[:after_time] < file[:mdate]
        return false
      end
    end
    
    return true
  end
  
  def log(type,msg)
    case type
    when :info
      STDOUT.puts "(net-sftp) #{msg}"
    when :error
      STDERR.puts "(net-sftp) #{msg}"
    end
  end
  
  # end class
end
