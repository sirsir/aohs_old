module AppUtils
  
  # To get some information of tool or application on server
  
  class ToolInfo
    
    def self.get_version(name)
      case name
      when "ruby"
        ruby_version
      when "gnuplot"
        gnuplot_version
      when "sox"
        sox_version
      when "speexenc"
        speexenc_version
      else
        nil
      end
    end
    
    def self.ruby_version
      return cmd_rs("#{Settings.libexec.ruby} --version")
    end
  
    def self.gnuplot_version
      return cmd_rs("#{Settings.libexec.gnuplot} --version")
    end
  
    def self.sox_version
      return cmd_rs("#{Settings.libexec.sox} --version")
    end
  
    def self.speexenc_version
      return cmd_rs("#{Settings.libexec.speexenc} --version")
    end
  
    def self.speexdec_version
      return cmd_rs("#{Settings.libexec.speexdec} --version")
    end
  
    def self.lame_version
      return cmd_rs("#{Settings.libexec.lame} --version")
    end
  
    def self.wget_version
      return cmd_rs("#{Settings.libexec.wget} --version")
    end
  
    def self.java_version
      return cmd_rs("#{Settings.libexec.java} -version")
    end
  
    def self.unoconv_version
      return cmd_rs("#{Settings.libexec.unoconv} --version")
    end
  
    def self.tar_version
      return cmd_rs("#{Settings.libexec.tar} --version")
    end
  
    def self.jpegoptim_version
      return cmd_rs("#{Settings.libexec.jpegoptim} -V")
    end
  
    def self.jruby_version
      return cmd_rs("#{Settings.libexec.jruby} -v")
    end
  
    def self.bzip2_version
      return check_exec(Settings.libexec.bzip2)
    end
  
    def self.unzip_version
      return check_exec(Settings.libexec.unzip)
    end
    
    protected
    
    def self.cmd_rs(cmd)
      begin
        result = `#{cmd}`
        return result.chop
      rescue => e
        return ""
      end
    end
    
    def self.check_exec(path)
      if File.exists?(path)
        return "Found"
      end
      return ""
    end
    
  end # end class

end