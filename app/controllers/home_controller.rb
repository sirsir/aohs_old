class HomeController < ApplicationController
  
  before_action :authenticate_user!
  before_action :goto_landing_page, only: [:index]
  
  def index

  end
  
  #
  # dashboard/landing page for qa
  #
  
  def portal
    
  end
  
  def qa
  
  end

  def nodas
    
  end
  
  private
  
  def goto_landing_page
    landing_page = current_user.landing_page_or_default
    case landing_page
    when 'qa_agent', 'qa_supervisor', 'qa_manager'
      redirect_to action: 'qa', ldp: landing_page
    when 'sale', 'sale_lead', 'sale_manager'
      redirect_to action: 'sale2', ldp: 'sale'
    when 'portal'
      redirect_to action: 'portal'
    else
      redirect_to action: 'portal'
    end
  end
  
end
