class AccountsController < ApplicationController

   include AuthenticatedSystem

   layout 'sessions'

   before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]

   # render new.rhtml
   def new
   end

   def create
      cookies.delete :auth_token
      # protects against session fixation attacks, wreaks havoc with
      # request forgery protection.
      # uncomment at your own risk
      # reset_session
      @user = Manager.new(params[:user])
      @user.register! if @user.valid?
      if @user.errors.empty?
         self.current_user = @user

         # [FIXME] temporaly, activation process is skipped.
         current_user.activate!

         redirect_back_or_default('/')
#         redirect_to login_path
         flash[:notice] = "Thanks for signing up! Please wait for authorization process."
      else
         flash[:error] = "Failed to register new account. Please try again"
         render :action => 'new'
      end
   end

   def activate
      self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
      if logged_in? && !current_user.active?
         current_user.activate!
         flash[:notice] = "Signup complete!"
      end
      redirect_back_or_default('/')
   end

   def suspend
      @user.suspend!
      redirect_to users_path
   end

   def unsuspend
      @user.unsuspend!
      redirect_to users_path
   end

   def destroy
      @user.delete!
      redirect_to users_path
   end

   def purge
      @user.destroy
      redirect_to users_path
   end

   protected
   def find_user
      @user = User.find(params[:id])
   end
end
