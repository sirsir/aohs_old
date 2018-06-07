#
# module for manage any actions of application who can access it
# permission of action will check by role of user
#

module SysPermission
  module CheckPermission
    
    def can_do?(modn,actn,user_id=nil)
      
      # parameter
      # modn = controller_name
      # actn = action_name.link_name
      
      is_permit  = true
      rs_txt     = "allowed"
      
      actn, lnkn = sub_action_name(actn)
      alias_actn = event_name(actn)
      actns      = [actn, alias_actn].uniq
      
      privilege  = find_privilege(modn, actns, lnkn)
      unless privilege.nil?
        user = get_user_o(user_id)
        if not found_permission?(privilege, user)
          is_permit = false
          rs_txt    = "denied"
        end
        role_id = user.role_id rescue 0
      else
        rs_txt << "-nomatch"
      end
      
      Rails.logger.info "Checked permission of #{modn}/#{actn}.#{lnkn}, #{rs_txt}"
      return is_permit
    end
    
    private
    
    def sub_action_name(actn)
      # format: action_name.link_name
      if actn =~ /^(.+)\.(.+)$/
        str = /^(.+)\.(.+)$/.match(actn)
        unless str.nil?
          actn, lnkn = str[1], str[2]
          return actn, lnkn
        end
      end
      return actn, nil
    end
    
    def event_name(actn)
      
      case actn.to_s.downcase.to_sym 
      when :index, :view
        return "view"
      when :new, :create, :edit, :update, :delete, :destroy, :manage
        return "manage"
      else
        return "undefined"
      end
      
    end
    
    def find_privilege(modn, actns, lnkn=nil)
      unless actns.empty?
        cache_name = "privilege_of_#{modn}_#{actns.join}"
        cache_name << "_#{lnkn}" unless lnkn.nil?
        Rails.cache.fetch(cache_name, expires_in: 1.hours) do
          Privilege.select([:id,:flag]).privilege_name(modn, actns, lnkn).first
        end
      else
        return nil
      end
    end
    
    def found_permission?(privilege,user)
  
      if user_info?(user)
        return false
      end
      
      if privilege.disabled?
        return false
      end
      
      px = {
        privilege_id: privilege.id,
        role_id:      user.role_id
      }
      
      rcount = Rails.cache.fetch("permission_of_#{privilege.id}_#{user.role_id}", expires_in: 1.hours) do
        Permission.where(px).count(0)
      end

      return (rcount > 0)
      
    end
    
    def user_info?(user)
      
      # false if no info
      return (user.nil? or (user.id.to_i <= 0 and user.role_id.to_i <= 0))
    
    end
    
    def except_modules?(modn)
      
      return NO_AUTHEN_CONTROLLERS.include?(modn.to_s)
    
    end
    
    def get_user_o(user_id=nil)
      
      o_user = User.new
      
      unless user_id.nil?
        o_user = User.select([:id,:role_id]).where(id: user_id).first
      else
        if defined?(current_user)
          o_user = current_user
        end
      end
    
      return o_user
    
    end
    
    def resolve_module_name(modn)
      
      case modn.to_s
      when "call_evaluation"
        return "evaluations"
      end
      
      return modn
      
    end
    
  end
  
  module ActionPermission
    
    include CheckPermission
    
    def permission_require
    
      modn, actn = permiss_parm
 
      if not except_modules?(modn)
        unless can_access?(modn,actn)
          if already_login?
            redirect_to_denied
          else
            redirect_to_login
          end
        end
      else
        return true
      end
      
    end
  
    def redirect_to_denied
      
      redirect_to controller: 'errors', action: 'denied'
      
    end
    
    def redirect_to_login
      
      redirect_to new_user_session_path
      
    end
    
    def already_login?
      
      return (defined?(current_user) and not current_user.nil?)
    
    end
    
    def can_view?(modn=nil)
      
      @can_view = {} unless defined? @can_view
      modn = get_mod_name(modn) if modn.nil?
      
      if @can_view[modn].nil?
        @can_view[modn] = can_access?(modn,:view)
      end
      
      return @can_view[modn]
      
    end
    
    def can_manage?(modn=nil)
    
      unless defined? @can_manage
        @can_manage = can_access?(get_mod_name(modn),:manage)
      end
      
      @can_manage
      
    end
    
    def can_doact?(act)
      
      # input format for permission check
      # <module>:<action>
      # <action>
      
      rs = act.match(/(.+):(.+)/)
      unless rs.nil?
        can_access?(rs[1],rs[2])  
      else
        can_access?(get_mod_name(nil),act)
      end
      
    end
    
    def is_admin?
      
      user = get_user_o
      
      return (user.nil? ? false : user.is_admin?)
      
    end
    
    private
    
    def can_access?(modn,actn)
 
      return can_do?(modn, actn)
    
    end
    
    def get_mod_name(modn)
     
      return (modn.nil? ? params[:controller].to_s.to_sym : modn.to_sym)

    end
    
    def permiss_parm

      return params[:controller].to_s.downcase, params[:action].to_s.downcase
    
    end
    
  end
  
  class KlsPermission
    
    include CheckPermission 
  
  end
  
  def self.can_do?(user_id,modn,actn)
    
    kps = KlsPermission.new
    return kps.can_do?(modn,actn,user_id)
    
  end
  
end