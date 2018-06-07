class ErrorsController < ApplicationController
  
  def index
    
    redirect_to controller: 'home', action: 'index'
    
  end
  
  def denied
    
  end
  
end
