class CallMailer < ApplicationMailer
  
  def send_call(users,msg,sender=nil)
    
    @msg        = msg[:message]
    @subj       = msg[:subject]
    @st_sec     = msg[:start_sec]
    
    @voice_log  = VoiceLog.where(id: msg[:voice_log_id]).first
    
    unless msg[:attach_file].blank?
      send_file = get_attache_file(@voice_log,msg[:attach_file])
      unless send_file.nil?
        attachments["#{@voice_log.output_filename}#{File.extname(send_file)}"] = File.read(send_file)
      end
    end
    
    emails = users.map { |u| u.email }
    
    mail(to: emails.join(', '), subject: default_subject(@subj)) 
  
  end

  def default_subject(subj)
    
    return "#{subj}"
  
  end
  
  def get_attache_file(voice_log,format)
    
    downloaded_file = WorkingNet.file_download(voice_log.voice_file_url)
    
    unless downloaded_file.nil?
      return FileConversion.audio_convert(format.to_sym,downloaded_file)
    end
    
    return nil
  
  end
  
end
