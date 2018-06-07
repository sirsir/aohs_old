class VoiceLogAtlusrMap < ActiveRecord::Base
  
  belongs_to  :voice_log
  
  def self.create_or_update(vl)
    vam = where(voice_log_id: vl.id).first
    if vam.nil?
      vam = {
        voice_log_id: vl.id
      }
      vam = new(vam)  
    end
    vam.set_voice_log(vl)
    if vam.set_atluser_id
      vam.save
    end
  end
  
  def set_voice_log(vl)
    @voice_log = vl
  end
  
  def set_atluser_id
    uaa = lookup_atluser_log
    unless uaa.nil?
      self.user_atl_id = uaa.id
      return true
    end
    return false
  end
  
  private
  
  def lookup_atluser_log
    
    # find latest user data - autocall
    # a. by agent_id
    
    if defined? @voice_log and not @voice_log.nil?
      if @voice_log.agent_id.to_i > 0
        uaa = UserAtlAttr.not_deleted.find_by_user_id(@voice_log.agent_id).order_by_mapping.first
        unless uaa.nil?
          return uaa
        end
      end
    end
    
    return nil
  end
  
end
