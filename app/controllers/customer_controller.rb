class CustomerController < ApplicationController

  layout "control_panel"

  before_filter :login_required

  def index

    @page = (params[:page].to_i <= 0 ? 1 : params[:page].to_i)
    
    sort_key = ""  
    case params[:col]
    when /name/
      sort_key = "customer_name"
    else
      sort_key = "customer_name"
    end
    
    sort_key = "#{sort_key} #{check_order_name(params[:sort])}" 
    
    conditions = []
    if params.has_key?(:name) and not params[:name].empty?
      conditions << "customer_name like '%#{params[:name]}%'"
    end
    
    if params.has_key?(:phone) and not params[:phone].empty?
      conditions << "customer_numbers.number like '%#{params[:phone]}%'"
    end
    
    @customers = Customers.paginate(
                              :page => params[:page],
                              :per_page => $PER_PAGE,
                              :order => sort_key,
                              :conditions => conditions.join(' and '),
                              :include => :customer_numbers)
    
  end

  def new

    @customer = Customers.new
    
  end

  def create

    begin
      customer = params[:customer]
      @customer = Customers.new(customer)

      if @customer.save
        
        @customer = Customers.find(:first,:conditions => { :customer_name => @customer.customer_name })

        log("Add","Customer",true,"id:#{@customer.id}, name:#{@customer.customer_name}") 
        flash[:notice] = 'Create customer has been successfully.'

        redirect_to :controller => 'customer',:action => 'index'

      else

        log("Add","Customer",false,@customer.errors.full_messages.compact)
        flash[:message] = @customer.errors.full_messages

        render :action => 'new'
      end

    rescue => e

      log("Add","Customer",false,e.message)
      redirect_to :controller => 'customer',:action => 'index'

    end
 
  end

  def edit

    @customer = Customers.find(params[:id])

  end

  def update
    
    begin
       @customer = Customers.find(params[:id])
       if @customer.update_attributes(params[:customer])
          log("Update","Customer",true,"id:#{@customer.id}, name:#{@customer.customer_name}")
          flash[:notice] = 'Update agent has been successfully.'

          redirect_to :controller => 'customer',:action => 'index'
       else
          log("Update","Customer",false,"id:#{@customer.id}, #{@customer.errors.full_messages.compact}")
          flash[:message] = @customer.errors.full_messages

          render :controller => 'customer',:action => "edit"
       end
    rescue
       flash[:error] = "Update customer have some problem. Please try again."
       redirect_to :controller => 'customer',:action => 'index'
    end

  end

  def delete

    @customer = Customers.find(params[:id])
    @customer.destroy
    
    redirect_to :action => 'index'
    
  end

  def create_customer

    result = ""
    cust_name = nil

    if params.has_key?(:cust_name) and not params[:cust_name].empty?
      cust_name = params[:cust_name].to_s.strip
    end

    begin
      customer = {:customer_name => cust_name}
      customer = Customers.new(customer)

      if customer.save
        result = 'success'
        log("Add","Customer",true,"id:#{customer.customer_name}, name:#{cust_name}")    
      else
        log("Add","Customer",false,"id:-, name:#{cust_name},#{customer.errors.full_messages}")
        result = customer.errors.full_messages.join(',')
      end
    rescue => e
      log("Add","Customer",false,"id:-, name:#{cust_name}, #{e.message}")
      result = e.message 
    end
    
    render :text => result
    
  end

  def update_customer

    result = ""
    cust_id = 0
    
    if params.has_key?(:cust_id) and not params[:cust_id].empty?
      cust_id = params[:cust_id].to_i
    end

    begin
      customer = Customers.find(cust_id)
      if customer.update_attributes({:customer_name => cust_name} )
        log("Update","Customer",true,"id:#{cust_id}, name:#{customer.customer_name}") 
        result = 'success'
      else
        log("Update","Customer",false,"id:#{cust_id}, name:#{customer.customer_name}")
      end
    rescue => e
      log("Update","Customer",false,"id:#{cust_id}, #{e.message}") 
      result = e.message
    end

    render :text => result
    
  end

  def customer_id

    customer_id = 0

    if params.has_key?(:cust_name) and not params[:cust_name].empty?
        customer = Customers.find(:first,:conditions => "customer_name like '#{params[:cust_name]}'")
        unless customer.blank?
          customer_id = customer.id
        end
    end

    render :layout => false, :text => customer_id
    
  end

  def list
    
    customers = []

    if params.has_key?(:cust_name) and not params[:cust_name].empty?

        customers = Customers.find(:all,:conditions => "customer_name like '#{params[:cust_name]}%'")
        customers_temp = customers
        customers = []
        customers_temp.each { |c| customers << { :name => c.customer_name} }
    end

    render :json => customers

  end

  def update_phones

    result_txt = "success"

    if params.has_key?(:cust_id) and not params[:cust_id].empty?
      if params.has_key?(:phones) and not params[:phones].empty?

        customer = Customers.find(:first,:conditions => {:id => params[:cust_id]})

        unless customer.blank?

          if params.has_key?(:new_custn) and not params[:new_custn].empty?
            if params[:new_custn].strip != customer.customer_name
              log("Update","Customer",true)
              customer.update_attributes(:customer_name => params[:new_custn].strip)
            end
          end

          # clear all
          CustomerNumbers.destroy_all(:customer_id => customer.id)

          log("Update","CustomerPhones",true,"customer_id:#{params[:cust_id]}")
          
          unless params[:phones] == "removeall"
            new_phone = (CGI::unescape(params[:phones])).split(',').compact
            new_phone = new_phone.uniq
            new_phone.each do |p|
              custn = CustomerNumbers.new(
                        :customer_id => customer.id,
                        :number => p.strip)
              custn.save!
            end
          else
            # clear phone
          end
        else
          result_txt = 'nocust'
        end

      end
    end

    render :layout => false, :text => result_txt

  end

  def list_phones
    
    phones = []

    if params.has_key?(:cust_name) and not params[:cust_name].empty?

      customer = Customers.find(:first,:conditions => "customer_name like '#{params[:cust_name]}'")

      unless customer.blank?
        phones = CustomerNumbers.find_all_by_customer_id(customer.id)
        phone_temp = phones
        phones = []
        phone_temp.each { |p| phones << {:number => p.number } }
      end

    end

    render :json => phones

  end
  
end
