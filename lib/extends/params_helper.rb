#
# extended class for filter form in maintenance page
# - filter parameters
# - orders parameters
#

module ParamsHelper
  
  module Controller
    
    TwoDateRegex = /^(\d{4}-\d{2}-\d{2})( - )(\d{4}-\d{2}-\d{2})$/
    TwoDateTimeRegex = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2})( - )(\d{4}-\d{2}-\d{2} \d{2}:\d{2})$/
    
    def isset_param?(name)
      return (params.has_key?(name) and got_param_value?(name))
    end
    
    def get_param(name)
      bval = params[name].to_s
      aval = params[name].to_s
      if isset_param?(name)
        aval = conv_val(aval)
      else
        aval = nil
      end
      keep_filter_params(name, aval)
      return aval
    end
    
    def get_order_by(col_default, order_by_default="asc")
      p_orderby = sort_param(order_by_default)
      p_col = sort_col_param(col_default)
      
      # keep params
      keep_page_params("sort",p_orderby)
      keep_page_params("order",p_col)
      order_by_string(p_col, p_orderby)
    end
    
    def index_with_filter_url
      p_url = {
        action: "index"
      }
      p_url = p_url.merge(restore_filter_params)
      p_url
    end
    
    private
    
    def keep_filter_params(name,val)
      @filter_on = true
      
      unless defined?(@ss_filters)
        @ss_filters = []
      end
      
      unless defined?(@parm_filters)
        @parm_filters = {}
      end
      
      ss_name = ss_name_filtered
      
      unless val.nil?
        @ss_filters << [name,val].join("=")
        @parm_filters[name] = val
        session[ss_name] = @ss_filters.uniq.join("|")
        Rails.logger.info "Keep filter parameters to session #{session[ss_name]}"
      else
        session.delete(ss_name)
      end
      
      check_filter_on
    end
    
    def check_filter_on
      cond_count = 0
      @ss_filters.each do |f|
        unless f =~ /^((per=)|(page=)|(sort=)|(order=))/
          cond_count += 1
        end
      end
      @filter_on = (cond_count > 0)
    end
    
    def restore_filter_params  
      ss_name = ss_name_filtered
      tmp = {}
      if session[ss_name].present?
        filters = session[ss_name].split("|")
        filters.each do |fl|
          n, v = fl.split("=")
          tmp[n.to_sym] = v
        end
      end
      return tmp
    end
    
    def sort_param(default_order="asc")
      s_key = :sort
      unless DB_ORDER_BY.include?(params[s_key])
        params[s_key] = default_order
      end
      return params[s_key]
    end
    
    def sort_col_param(col_name)
      s_key = :order
      if isset_param?(s_key)
        return params[s_key].to_s.strip.downcase
      else
        return col_name
      end
    end
    
    def conv_val(p_val)
      c_val = p_val
      if c_val.is_a?(String)
        c_val = c_val.to_s.chomp.strip
        if c_val.length > 0
          if is_two_dates?(c_val)
            c_val = split_two_dates(c_val)
          elsif is_two_datetimes?(c_val)
            c_val = split_two_datetimes(c_val)
          end
        else
          c_val = nil
        end
      end
      return c_val
    end
    
    def ss_name_filtered
      return [params[:controller].to_s, params[:action].to_s, "filter"].join("_").to_sym
    end
    
    def order_by_string(pc, po)
      return "#{pc} #{po}"
    end
    
    def is_two_dates?(d_str)
      return (not d_str.to_s.strip.match(TwoDateRegex).blank?)
    end
    
    def is_two_datetimes?(dt_str)
      return (not dt_str.to_s.strip.match(TwoDateTimeRegex).blank?)
    end
  
    def split_two_dates(d_str)
      dates = d_str.to_s.strip.split(TwoDateRegex)
      dates.shift
      return [dates.first, dates.last]
    end

    def split_two_datetimes(d_str)
      dates = d_str.to_s.strip.split(TwoDateTimeRegex)
      dates.shift
      return [dates.first, dates.last]
    end
  
    def got_param_value?(name)
      return (params[name].to_s.strip.length > 0)
    end
    
    # end controller
  end
  
  module Helper
    
    def index_with_filter_url
      p_url = {
        action: "index"
      }
      p_url = p_url.merge(restore_filter_params)
      return p_url
    end
    
    private
    
    def restore_filter_params
      ss_name = ss_name_filtered
      tmp = {}
      
      Rails.logger.info "Get filter parameter from session - #{ss_name}#{session[ss_name]}"
      if session[ss_name].present?
        filters = session[ss_name].split("|")
        filters.each do |fl|
          n, v = fl.split("=")
          tmp[n.to_sym] = v
        end
      end
      
      return tmp 
    end
  
    def ss_name_filtered
      # key name to store parameters
      # name: <controller_name>_<action_name>_filter
      return [params[:controller].to_s, "index", "filter"].join("_").to_sym
    end
  
    # end helper
  end
end
