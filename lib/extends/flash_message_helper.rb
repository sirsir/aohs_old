module FlashMessageHelper
  module Controller
  
    def flash_notice(mo_obj, event_name)
      dsp_name = get_target_info(mo_obj)
      dsp_msgx = nil
      
      case event_name
      when :new
        dsp_msgx = "#{dsp_name} has been created."
      when :update
        dsp_msgx = "#{dsp_name} has been updated."
      when :delete
        dsp_msgx = "#{dsp_name} has been deleted."
      when :cancel_delete
        dsp_msgx = "Delete has been cancelled for #{dsp_name}."
      when :change_password
        dsp_msgx = "Password has been changed."
      end
      
      flash[:notice] = dsp_msgx unless dsp_msgx.nil?
    end
  
    private
    
    def get_target_info(mo_obj)
      target_name = "The record"
      if defined? mo_obj.name
        target_name = mo_obj.name
      elsif defined? mo_obj.login
        target_name = mo_obj.login
      elsif defined? mo_obj.title
        target_name = mo_obj.title
      end
      return target_name
    end
    
    # end
  end
end