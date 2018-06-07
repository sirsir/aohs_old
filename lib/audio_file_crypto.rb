class AudioFileCrypto
  
  def self.decrypt(file_path, options={})
    afc = AudioFileCrypto.new(file_path, options)
    return afc.decrypt_file
  end
  
  def initialize(file_path, options={})
    
    @errors = []
    @audio_file = file_path
    @opts = options
    
    keys_path
  
  end
  
  def decrypt_file
    
    if require_decrypt?
      do_decrypt
    end
    
    return @audio_file
  
  end
  
  protected
  
  def do_decrypt
    
    audio_file = @audio_file
    tmp_file = @audio_file.gsub(".#{Settings.qlogger.cypto.encrypt_fext}","") + ".tmp"
    out_file = @audio_file.gsub(".#{Settings.qlogger.cypto.encrypt_fext}","")
    
    File.rename(audio_file, tmp_file)    
    
    cml = Cocaine::CommandLine.new(Settings.libexec.openssl, Settings.libexec.decrypt_audio)
    cml.run(infile: tmp_file, outfile: out_file, private_key_file: @private_key)
    
    if File.exists?(out_file)
      File.delete(tmp_file)
      @audio_file = out_file
    else
      @audio_file = tmp_file
      @errors << "Decrypt file was not successully"
    end
    
  end
  
  def require_decrypt?
    
    enc_exts = Settings.qlogger.cypto.encrypt_fext.split(",").map { |x| ".#{x.strip}" }
    in_ext = File.extname(@audio_file)
    
    if Settings.qlogger.cypto.enable and enc_exts.include?(in_ext)
      return true
    end
    
    return false
  
  end
  
  def keys_path  
    
    [Settings.server.directory.conf, File.join(Rails.root, 'config', 'keys')].each do |dir|
      @private_key = File.join(dir, Settings.qlogger.cypto.decrypt_key)
      @public_key = File.join(dir, Settings.qlogger.cypto.encrypt_key)
      if File.exists?(@private_key) and File.exists?(@public_key)
        break
      end
    end
    
  end
  
end