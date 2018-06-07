module PaginatesHelper
  
  module PageHelper
    
    def current_or_default_perpage
      
      xpage, xper_page = 1, Settings.pagination.per_pages.first
      
      if params.has_key?(:page) and not params[:page].empty?
        xpage = params[:page]
      end
      
      if params.has_key?(:per) and not params[:per].empty?
        xper_page = params[:per]
      end
      
      keep_page_params("page",xpage)
      keep_page_params("per",xper_page)
      
      return xpage, xper_page
    
    end
    
    def row_no(i)
      
      p   = get_ppage(params[:page].to_i)
      pp  = get_pperpage(params[:per].to_i)
      
      calc_row_no(i, p ,pp)
    
    end
  
    private
    
    def keep_page_params(name,val)
 
      unless defined?(@ss_filters)
        @ss_filters = []
      end
      
      @ss_filters << [name,val].join("=")
      
      ss_name = ss_name_paginate
      session[ss_name] = @ss_filters.uniq.join("|")

    end
    
    def ss_name_paginate
      
      [params[:controller].to_s, params[:action].to_s, "filter"].join("_").to_sym
    
    end
    
    def get_ppage(p)
      
      p <= 0 ? 1 : p
    
    end
    
    def get_pperpage(pp)
      
      pp <= 0 ? 25 : pp
      
    end
    
    def calc_row_no(i,p,pp)
      
      (((p-1)*pp) + i + 1)
      
    end
    
  end
  
end