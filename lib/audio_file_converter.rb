class AudioFileConverter
  
  # convert for download
  def self.convert_from_url(url,out_fmt=:spx)
    return do_convert(url, out_fmt)
  end
  
  private
  
  def self.do_convert(url, out_fmt)
    
    s_url = url
    
    # download from server
    a_file = File.join("/tmp", File.basename(url))
    a_ext = File.extname(a_file)
    cmd = "wget -q #{s_url} -T 5 -O #{a_file}"
    STDOUT.puts "[Download VoiceFile]: #{cmd}"
    system cmd
    unless File.exists?(a_file)
      return false
    end
    
    # spx?
    if a_ext == ".spx"
      if out_fmt == :spx
        return a_file
      else
        b_file = a_file.gsub(".spx",".wav") 
        cmd = "speexdec #{a_file} #{b_file}"
        STDOUT.puts "[Download VoiceFile]: #{cmd}"
        system cmd
        if File.exists?(b_file)
          File.delete(a_file)
          a_file = b_file
          a_ext = File.extname(a_file)
        else
          return false
        end
      end
    end
    
    # wav?
    if a_ext == ".wav"
      if out_fmt == :wav
        return a_file
      else
        b_file = a_file.gsub(".wav",".pcm.wav")
        cmd = "sox -r 8000 -c 2 #{a_file} -e signed-integer -c 2 #{b_file}"
        STDOUT.puts "[Download VoiceFile]: #{cmd}"
        system cmd
        if File.exists?(b_file)
          File.delete(a_file)
          a_file = b_file
          a_ext = File.extname(a_file)
        else
          return false
        end
      end
    end
    
    # spx?
    if out_fmt == :spx
      b_file = a_file.gsub(".pcm.wav",".spx")
      cmd = "speexenc #{a_file} #{b_file}"
      STDOUT.puts "[Download VoiceFile]: #{cmd}"
      system cmd
      if File.exists?(b_file)
        File.delete(a_file)
        return b_file
      end
    end
    
    # mp3 ?
    if out_fmt == :mp3
      b_file = a_file.gsub(".pcm.wav", ".mp3")
      cmd = "lame --silent #{a_file} #{b_file}"
      STDOUT.puts "[Download VoiceFile]: #{cmd}"
      system cmd
      if File.exists?(b_file)
        File.delete(a_file)
        return b_file
      end      
    end

    return false
  
  end
  
end