require 'fileutils'

module FileConversion

  ACCEPTED_FILE_FORMATS = {
    doc: [ :xlsx, :xls, :csv, :pdf ],
    audio: [ :spx, :wav, :mp3, :opus ]
  }
  
  class DocsConv
  
    def initialize(from_file, target_format)
      @errors     = []
      @from_file  = nil
      @to_file    = nil
      @out_format = target_format     
      @in_format  = nil
      
      if correct_input_file?(from_file) and correct_target?(target_format)
        @from_file  = from_file
      end
      
    end
    
    def convert?
      
      begin
        if need_convert?
          args = Settings.libexec.unoconv_args
          if input_type?(:csv)
            args = Settings.libexec.unoconv_args_csv
          end
          cml = Cocaine::CommandLine.new(Settings.libexec.unoconv, args)
          cml.run(output_format: @out_format.to_s, input_file: @from_file)          
        end
      rescue => e
        @errors << e.message
      end
      
      return convert_success?

    end

    def errors
      @errors
    end

    def to_file
      @to_file  
    end
    
    private
    
    def correct_input_file?(from_file)
      
      file_ext = File.extname(from_file.to_s).gsub(/\./,"")
      @in_format = file_ext.to_sym 
      
      case false
      when (not from_file.nil?)
        @errors << "No input file"
      when File.exists?(from_file)
        @errors << "Input file #{from_file} does not exist"
      when ACCEPTED_FILE_FORMATS[:doc].include?(file_ext.to_sym)
        @errors << "Invalid input file extension"
      else
        return true
      end
      
      return false
    
    end
    
    def correct_target?(target_format)
      
      unless ACCEPTED_FILE_FORMATS[:doc].include?(target_format.to_sym)
        @errors << "Invalid output file format"
      else
        return true
      end
      
      return false
      
    end
    
    def convert_success?
      
      to_file = @from_file.gsub(/\.\w{3,4}$/,"." + @out_format.to_s)
      
      if File.exists?(to_file)
        @to_file = to_file
        return true
      else
        @errors << "No converted file."
        return false
      end
      
    end
    
    def need_convert?
      
      to_file = @from_file.gsub(/\.\w{3,4}$/,"." + @out_format.to_s)
      return (not @from_file == to_file)
      
    end
    
    def input_type?(ftype)
      
      @in_format == ftype
    
    end
    
  end
  
  class AudioConv
  
    def initialize(from_file, output_format, opts={})
      @src_file = from_file
      @in_fmt = File.extname(@src_file).gsub(".","")
      @out_fmt = output_format.to_s
      @opts = opts
      @temp_files = []
      @errors = []
      log :info, "trying to convert audio file, src-file=#{@src_file}, output-format=#{output_format}"
    end
    
    def to_file
      copy_tmp
      if @errors.empty?
        start_convert
        move_back
        remove_temp_file
      end
      see_error
      return @new_file
    end
    
    def errors
      return @errors
    end
    
    def see_error
      unless @errors.empty?
        @errors.each { |e|
          log :error, e
        }
      end
    end
    
    private
    
    def copy_tmp
      @original_file = "#{@src_file}"
      
      if @src_file.start_with?(Settings.server.directory.tmp)
        # already copied to tmp, skip to create new one
        return true
      end
      
      # create new temporary file
      @src_file = @src_file.gsub(File.dirname(@src_file), "")
      @src_file = File.join(Settings.server.directory.tmp, @src_file)
      
      unless File.exist?(@src_file)
        FileUtils.copy(@original_file, @src_file)
      end

      unless File.exist?(@src_file)
        @errors << "cannot create work file #{@src_file}"
      else
        @temp_files << @src_file
        log :info, "created work file from #{@original_file} to #{@src_file}"
      end
    end
    
    def move_back
      @new_file = get_nfname(@original_file, @out_fmt)      
      if replace_new_file?
        FileUtils.copy(@src_file, @new_file)
      end
      unless File.exist?(@new_file)
        @errors << "Cannot copy converted file to #{@new_file}"
      end
    end
    
    def remove_temp_file
      @temp_files.each do |tfile|
        File.delete(tfile) if File.exists?(tfile)  
      end
    end
    
    def start_convert
      log :info, "convert audio file from #{@in_fmt} to #{@out_fmt}"

      if to_pcm?
        to_pcm
      end
      
      if to_spx?
        to_spx
      end
      
      if to_mp3?
        to_mp3
      end
      
      if to_wav?
        to_wav
      end
      
      if to_mono?
        to_wav_mono
      end
    end
    
    def replace_new_file?
      return true
    end
    
    def to_wav?
      return ((@out_fmt == "wav"))
    end
    
    def to_pcm?
      return ((@in_fmt == "spx") or (@out_fmt == "spx") or (@out_fmt == "mp3"))
    end
    
    def to_spx?
      return ((@out_fmt == "spx"))
    end
    
    def to_mp3?
      return ((@out_fmt == "mp3"))
    end
    
    def to_mono?
      return @opts[:mono] == true  
    end
    
    def to_pcm
      
      out_fname = get_nfname(@src_file,'pcm.wav')
      cmd       = nil
      
      if @in_fmt == "spx"
        cml = Cocaine::CommandLine.new(Settings.libexec.speexdec, Settings.libexec.speexdec_args)
        cml.run(src_file: @src_file, dest_file: out_fname)
      end
      
      if @in_fmt == "wav" and (@out_fmt == "spx" or @out_fmt == "mp3")
        cml = Cocaine::CommandLine.new(Settings.libexec.sox, Settings.libexec.sox_args_wav)
        cml.run(src_file: @src_file, dest_file: out_fname)
      end
      
      unless File.exists?(out_fname)
        @errors << "No converted file #{out_fname}"
      else
        @temp_files << out_fname
        @src_file = out_fname
        log :info, "converted file to '#{out_fname}'"
      end
      
    end
    
    def to_spx
      
      out_fname = get_nfname(@src_file,'spx')
      cmd       = nil
      
      if @out_fmt == "spx"
        cml = Cocaine::CommandLine.new(Settings.libexec.speexenc, Settings.libexec.speexenc_args)
        cml.run(src_file: @src_file, dest_file: out_fname)
      end
      
      unless File.exists?(out_fname)
        @errors << "No converted file #{out_fname}"
      else
        @temp_files << out_fname
        @src_file = out_fname
        log :info, "converted file to '#{out_fname}'"
      end
      
    end
    
    def to_mp3

      out_fname = get_nfname(@src_file,'mp3')
      cmd       = nil
      
      if @out_fmt == "mp3"
        cml = Cocaine::CommandLine.new(Settings.libexec.lame, Settings.libexec.lame_args)
        cml.run(in_file: @src_file, out_file: out_fname)
      end
      
      unless File.exists?(out_fname)
        @errors << "No converted file #{out_fname}"
      else
        @temp_files << out_fname
        @src_file = out_fname
        log :info, "converted file to '#{out_fname}'"
      end
      
    end
    
    def to_wav_mono
      
      out_fname = @src_file.gsub(".wav",".mono.wav")
      
      if @out_fmt == "wav"
        cml = Cocaine::CommandLine.new(Settings.libexec.sox, Settings.libexec.sox_args_mono)
        cml.run(src_file: @src_file, out_file: out_fname)
      end

      unless File.exists?(out_fname)
        @errors << "No converted mono file #{out_fname}"
      else
        @temp_files << out_fname
        @src_file = out_fname
        log :info, "converted file to '#{out_fname}'"
      end

    end
    
    def to_wav
      if File.extname(@src_file) == ".wav"
        out_fname = @src_file.gsub(".wav",".tmp.wav")
        # norn file
        cml = Cocaine::CommandLine.new(Settings.libexec.sox, Settings.libexec.sox_args_nor)
        cml.run(src_file: @src_file, dest_file: out_fname)
        if File.exists?(out_fname)
          # adjust volume
          File.rename(out_fname, @src_file)
          cml = Cocaine::CommandLine.new(Settings.libexec.sox, Settings.libexec.sox_args_vol)
          cml.run(src_file: @src_file, dest_file: out_fname)
        end
        unless File.exists?(out_fname)
          @errors << "No converted file #{out_fname}"
        else
          File.rename(out_fname, @src_file)
          @temp_files << out_fname
          log :info, "converted file to '#{out_fname}'"
        end
      end
    end
    
    def get_nfname(fname,to_ext)      
      fname.gsub(File.extname(fname),".#{to_ext.to_s}")
    end
    
    def log(ltype, msg)
      begin
        case ltype
        when :info
          Rails.logger.info "(audio-file-conversion) #{msg}"
        when :error
          Rails.logger.error "(audio-file-conversion) #{msg}"
        end
      rescue
      end
    end
    
    # end class
  end
  
  ##
  # method to call
  
  def self.docs_convert(output_format,from_file,opts={})
    
    dc = DocsConv.new(from_file, output_format)
    if dc.errors.empty? and dc.convert?
      return dc.to_file
    else
      STDERR.puts dc.errors.join("\n")
      if opts[:skip_err] == true
        return from_file
      else
        return nil        
      end
    end
    
  end

  def self.audio_convert(output_format,from_file,opts={})
    
    ac = AudioConv.new(from_file, output_format, opts)
    return ac.to_file
  
  end
  
end
