# This controller handles login or logout function of the site.
class SessionsController < ApplicationController

   require 'socket'

   def index
     redirect_to login_path
   end
   
   def new
     @reset = false
   end

   def create
     
      flash[:loginfailed] = nil
       
      @reset = false
      begin
        
        if not params[:login].empty? and params[:password] == Aohs::DEFAULT_PASSWORD
          
          @old_password = Aohs::DEFAULT_PASSWORD
          @reset = true
          render :action => 'new'
          
        else
          
          if params.has_key?(:change_password) and params[:change_password] == 'true'
              @old_password = Aohs::DEFAULT_PASSWORD
              flash[:loginfailed] = nil
              @reset = true
              user = User.find(:first,:conditions => {:login => params[:login]})
              unless user.nil?
                user = User.find(user.id)
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
            
            self.current_user = User.authenticate(params[:login], params[:password])
  
            if logged_in?
               if current_user.type == "Manager"
                 if params[:remember_me] == "1"
                    current_user.remember_me unless current_user.remember_token?
                    cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
                 end
                 #log("Login","Session",true,current_user.login)
                 flash[:loginfailed] = false
                 redirect_back_or_default(:controller => "top_panel",:action => "index")               
               else
                 destroy
               end
            else
               #log("Login","Session",false,"#{params[:login]}:#{User.error_msg}")
               flash[:loginfailed] = User.error_msg
               render :new
            end 
          
          end
        end
        
      rescue => e
        
		    log("Login","Session",false,"#{e.message}")
        redirect_to login_path
        
      end  
   end

   def destroy

      begin
        #log("Logout","Session",true,"#{current_user.login}")
        self.current_user.forget_me if logged_in?
        cookies.delete :auth_token
        reset_session 
      rescue => e
        #log("Logout","Session",false,e.message)
      end
      
      redirect_back_or_default login_path

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
   
end
