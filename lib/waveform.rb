require 'uri'
require 'fileutils'
require 'tilt'

class Waveform
  
  Winfo = Struct.new(:channels, :sample_rate, :duration)
  
  def initialize(id, opts={})  
    @errors = []
    @id = id
    @opts = opts
    @winfo = nil
  end
  
  def to_svg
    create_dat_file
    create_svg_file
    if errors?
      @errors.each { |e| STDERR.puts e }
      return nil
    else
      return svg_fname
    end
  end
  
  def errors?
    return (not @errors.empty?)  
  end
    
  private
  
  def create_dat_file
    return true if ((dat_file_exist? and inf_file_exist?) or errors?)
    
    get_voicelog
    get_audio_file
    unless errors?
      prepare_target_dir(@dat_fname)
      new_sample_rate = (@winfo.sample_rate.to_i/40).to_s
      
      cml = Cocaine::CommandLine.new(Settings.libexec.sox, Settings.libexec.sox_args_dat)
      cml.run(wav_fname: @audio_file, sample_rate: new_sample_rate, dat_fname: @dat_fname)
      
      #File.delete(@audio_file) if File.exist?(@audio_file)
      unless dat_file_exist?
        @errors << "No converted dat file."
      end
    end
  end
  
  def create_svg_file
    return true if errors?
    gnu_fname = plot_script
    cml = Cocaine::CommandLine.new(Settings.libexec.gnuplot, Settings.libexec.gnuplot_args_wf)
    cml.run(script_fname: gnu_fname)
    File.delete(gnu_fname)
    unless File.exists?(svg_fname)
      @errors << "Failed to generate svg file."
    end
    return svg_fname
  end
  
  def get_audio_file
    tmp_file = @voice_log.temporary_file({ audio_format: :wav })
    if tmp_file.nil? or not File.exists?(tmp_file.path)
      @errors << "Failed to download or get audio file."
    else
      fname = convert_if_not_wav(tmp_file.path)
      get_wav_info(fname)
      write_file_info
    end
    @audio_file = fname
  end
  
  def write_file_info
    
    file = File.new(info_fname,'w')
    
    file.puts "channels=#{@winfo.channels}"
    file.puts "sample_rate=#{@winfo.sample_rate}"
    file.puts "duration=#{@winfo.duration}"
    file.puts "filesize=unknown"
    
    file.close
    
  end
  
  def get_file_info
    
    @winfo = Winfo.new
    
    File.open(info_fname,'r') do |file|
      file.each_line do |line|
        key, val = line.strip.split("=")
        begin
          @winfo[key] = val
        rescue
        end
      end
    end

  end
  
  def convert_if_not_wav(fname)
    
    converted_file = FileConversion.audio_convert(:wav, fname)
    if not File.extname(fname) == ".wav" and not converted_file.nil?
      File.delete(fname)
      fname = converted_file
    end
    
    return fname
  
  end
  
  def get_wav_info(fname)
    @winfo = WaveInfo.new(fname)
  end
  
  def dat_file_exist?
    return File.exists?(dat_fname)
  end
  
  def inf_file_exist?
    return File.exists?(info_fname)
  end

  def dat_fname
    @dat_fname = mk_filename("#{@id}.dat")
    return @dat_fname
  end
  
  def info_fname
    @info_fname = mk_filename("#{@id}.info")
    return @info_fname
  end
  
  def svg_fname
    @svg_fname = mk_filename("#{@id}.svg") 
    return @svg_fname
  end
  
  def plot_script_fname
    return mk_filename("#{@id}.gnu")
  end
  
  def mk_filename(fname)
    return File.join(Settings.server.directory.audio_data,fname)
  end
  
  def get_voicelog
    @voice_log = VoiceLog.select("id, voice_file_url").where(id: @id).first
  end

  def prepare_target_dir(fname)
    
    dir   = File.dirname(fname)
    wdir  = WorkingDir::WorkingFolder.new(dir)
    unless wdir.is_exist?
      @errors.concat(wdir.errors)
    end
    
  end
  
  def plot_script
    
    get_file_info if @winfo.nil?
    
    w   = @opts[:width]
    h   = @opts[:height]

    fg_color = Settings.audioplayer.waveform.fg_color
    bg_color = Settings.audioplayer.waveform.bg_color
    bd_color = Settings.audioplayer.waveform.border_color
    
    pl  = 2      # per line
    lw  = 0.4    # line width
    
    # re-calculate pl .. sec
    if @winfo.duration.to_i > 60
      pl += @winfo.duration.to_i / (60 * 3)
    end
    
    gnu_cmd = Tilt.new('lib/templates/waveform.stereo.gnu.erb')
    if @winfo.channels.to_i == 1
      gnu_cmd = Tilt.new('lib/templates/waveform.mono.gnu.erb')
    end
    
    gnu_args = {
      w: w,
      h: h,
      svg_fname: svg_fname,
      bd_color: bd_color,
      bg_color: bg_color,
      dat_fname: dat_fname,
      pl: pl,
      lw: lw,
      fg_color: fg_color
    }
    cmd = gnu_cmd.render("",gnu_args)
    
    script_fname = plot_script_fname
    File.open(script_fname,'w') { |f| f.write(cmd) }
    
    unless File.exists?(script_fname)
      @errors << "Failed to create gnuplot script"
    end
    
    return script_fname
  
  end
  
  def default_opts(opts)
  
    if opts[:width].to_i <= 100
      opts[:width] = 1000
    else
      opts[:width] = opts[:width].to_i
    end
    
    opts
    
  end
  
end