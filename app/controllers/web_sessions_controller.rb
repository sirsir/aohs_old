class WebSessionsController < ApplicationController

  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    
    users = User.only_active.order(:login).all
    
    @unlock_users = []
    users.each do |u|
      next unless u.access_locked?
      @unlock_users << u
    end
    
  end
  
end
