class OperationLogsController < ApplicationController
  
  before_action :authenticate_user!
  
  layout LAYOUT_MAINTENANCE
  
  def index

    page, per = current_or_default_perpage

    @logs     = OperationLog.last_six_months.search(conditions_params).result
    @logs     = @logs.order_by(order_params).page(page).per(per)
    
  end
  
  private

  def order_params
    
    get_order_by(:created_at,:desc)

  end

  def conditions_params

    conds = {
      created_at_betw:      get_param(:log_date),
      log_type_eq:          get_param(:log_type),
      module_name_cont:     get_param(:module_name),
      event_type_cont:      get_param(:event_type),
      computer_name_cont:   get_param(:computer_name),
      remote_ip_cont:       get_param(:remote_ip),
      created_by_cont:      get_param(:created_by)
    }
    
    conds.remove_blank!
    
  end
  
end
