class ComputerLogsController < ApplicationController
  
  before_action :authenticate_user!
  layout LAYOUT_MAINTENANCE
  
  def index
    page, per = current_or_default_perpage
    @computer_logs    = ComputerLog.search(conditions_params).result
    @computer_logs    = @computer_logs.order_by(order_params)
    @computer_logs    = @computer_logs.page(page).per(per)
  end
  
  private
  
  def order_params
    get_order_by(:check_time,:desc)
  end

  def conditions_params
    conds = {
      check_date_betw:      get_param(:log_date),
      computer_name_cont:   get_param(:computer_name),
      remote_ip_cont:       get_param(:remote_ip),
      login_name_cont:      get_param(:login)
    }
    conds.remove_blank!
  end
  
end
