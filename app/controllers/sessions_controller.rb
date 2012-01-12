# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  skip_before_filter :verify_authenticity_token, :only => [:client_http_authenticate]
  
  def new
    @reset = false
  end

  def create

    flash[:loginfailed] = nil   
    @reset = false

    if not params[:login].empty? and params[:password] == Aohs::DEFAULT_PASSWORD and Aohs::ALLOW_CHANGE_PASS_FRMSCR
      @old_password = Aohs::DEFAULT_PASSWORD
      @reset = true
      render :action => 'new'
    else
      if params.has_key?(:change_password) and params[:change_password] == 'true' and Aohs::ALLOW_CHANGE_PASS_FRMSCR
        
        @old_password = Aohs::DEFAULT_PASSWORD
        flash[:loginfailed] = nil
        @reset = true
        
        user = User.alive.select({:login => params[:login]}).first
        if not user.nil?
          ##user = User.find(user.id)
          if user.update_attributes({:password => params[:password],:password_confirmation => params[:password_confirmation]})
            log("ChangePassword","Session",true,params[:login])
            redirect_to login_path
          else
            flash[:loginfailed] = "Change password was failed. Please try again."
            log("ChangePassword","Session",false,params[:login])
            render :action => 'new'
          end
        else
          redirect_to login_path
        end
      else
		
      logout_keeping_session!
      if Aohs::LOGIN_BY_AGENT
        user = User.authenticate(params[:login], params[:password])  
      else
        user = Manager.authenticate(params[:login], params[:password])  
      end
			
			if user and not user.is_expired_date?
			  # Protects against session fixation attacks, causes request forgery
			  # protection if user resubmits an earlier form using back
			  # button. Uncomment if you understand the tradeoffs.
			  # reset_session
			  self.current_user = user
			  new_cookie_flag = (params[:remember_me] == "1")
			  handle_remember_cookie! new_cookie_flag
			  redirect_to :controller => 'top_panel', :action => 'index'
			  ##redirect_back_or_default('/')
			else
			  flash[:loginfailed] = "Login has been failed, please check your username and password."
			  note_failed_signin
			  @login       = params[:login]
			  @remember_me = params[:remember_me]
			  render :action => 'new'
			end	
			
		end
	
	end

  end

  def destroy
    logout_killing_session!
    redirect_to :controller => 'top_panel', :action => 'index'
    #redirect_back_or_default('/', :notice => "You have been logged out.")
  end

   def error
 
   end

   def expired?(expired_date)
       expired_date <= Date.today
   end
   
   def http_authenticate
     
     user_login = params[:user]
     password = params[:pass]

     u = User.authenticate(user_login, password)

     unless u.nil?
       render :text => 'success'
     else
       render :text => 'failed'
     end

   end

   def client_http_authenticate
     
     user_login = params[:user]
     password = params[:pass]

     u = User.authenticate(user_login, password)

     unless u.nil?
       render :json => {:success => true, :message => "success", :user => u.login, :display_name => u.display_name }
     else
       render :json => {:sucesss => false, :message => "failed" }
     end

   end

protected
  # Track failed login attempts
  def note_failed_signin
    flash.now[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
