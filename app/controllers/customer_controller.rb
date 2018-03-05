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
      @customer_name = CGI::unescape(params[:name]).strip
      conditions << "customer_name like '%#{@customer_name}%'"
    end
    
    if params.has_key?(:phone) and not params[:phone].empty?
      conditions << "customer_numbers.number like '%#{params[:phone]}%'"
    end

    if params.has_key?(:car) and not params[:car].empty?
      @car_id = CGI::unescape(params[:car]).strip
      conditions << "car_numbers.car_no like '%#{@car_id}%'"
    end
    
    if Aohs::MOD_CUST_CAR_ID
      @customers = Customer.alive.includes([:customer_numbers,:car_numbers]).where(conditions.join(' and ')).order(sort_key) 
    else
      @customers = Customer.alive.includes([:customer_numbers]).where(conditions.join(' and ')).order(sort_key) 
    end
    
    @customers = @customers.paginate(:page => params[:page],:per_page => $PER_PAGE)
    
  end

  def new
    
    @customer = Customer.new
    
  end

  def create

    begin
      customer = params[:customer]
      @customer = Customer.new(customer)
      
      car_correct = true
      if params.has_key?(:carno) and not params[:carno].empty? 
         car_correct = CarNumber.valid_car_pattern(params[:carno])         
      end
    
      if car_correct and @customer.save
                
        result = @customer.update_phones(params[:phone])
        
        if Aohs::MOD_CUST_CAR_ID
          result = @customer.update_carnos(params[:carno])  
        end
        
        log("Add","Customer",true,"id:#{@customer.id}, name:#{@customer.customer_name}") 
        flash[:notice] = 'Create customer has been successfully.'

        redirect_to :controller => 'customer',:action => 'index'

      else
        
        if car_correct
          flash[:message] = @customer.errors.full_messages
        else
          flash[:message] = "Car number is incorrect pattern" 
        end
        
        ##log("Add","Customer",false,@customer.errors.full_messages.compact)
        
        render :action => 'new'
      end

    rescue => e

      log("Add","Customer",false,e.message)
      redirect_to :controller => 'customer',:action => 'index'

    end
 
  end

  def edit

    @customer = Customer.find(params[:id])

  end

  def update
    
    begin
       @customer = Customer.find(params[:id])
       
        if params.has_key?(:carno) and not params[:carno].empty? 
           cars = []
           params[:carno].each { |id,c| cars << c.strip }
           car_correct = CarNumber.valid_car_pattern(cars)
        else
           car_correct = true
        end
       
       if car_correct and @customer.update_attributes(params[:customer])
          log("Update","Customer",true,"id:#{@customer.id}, name:#{@customer.customer_name}")
          flash[:notice] = 'Update agent has been successfully.'

          result = @customer.update_phones(params[:phone])
          if Aohs::MOD_CUST_CAR_ID
            result = @customer.update_carnos(params[:carno])  
          end 
          
          render :controller => 'customer',:action => "index"
       else
         
          if not car_correct
            flash[:message] = "Car number is incorrect pattern" 
          else
            flash[:message] = @customer.errors.full_messages
          end       
        
          log("Update","Customer",false,"id:#{@customer.id}, #{@customer.errors.full_messages.compact}")

          render :controller => 'customer',:action => "edit"
       end
    rescue => e
       flash[:error] = "Update customer have some problem. Please try again."
       redirect_to :controller => 'customer',:action => 'index'
    end

  end

  def delete
  
    customer_id = params[:id].to_i
    @customer = Customer.find(customer_id)
    if @customer
      Customer.delete(@customer)
      log("Delete","Customer",true,"id:#{@customer.id},name:#{@customer.customer_name}")
      #@customer.update_attributes({:flag => Aohs::FLAG_DELETE})
    end
    @customer.destroy
    
    redirect_to :action => 'index'
    
  end

  def create_customer

    result = { :msg => nil, :cust_id => nil }
    cust_name = nil

    if params.has_key?(:cust_name) and not params[:cust_name].empty?
      cust_name = params[:cust_name].to_s.strip
    end
 
    begin
      customer = {:customer_name => cust_name}
      customer = Customer.new(customer)

      if customer.save
        result[:msg] = 'success'
        result[:cust_id] = customer.id
        log("Add","Customer",true,"id:#{customer.customer_name}, name:#{cust_name}")    
      else
        log("Add","Customer",false,"id:-, name:#{cust_name},#{customer.errors.full_messages}")
        result[:msg] = customer.errors.full_messages.join(',')
      end
    rescue => e
      log("Add","Customer",false,"id:-, name:#{cust_name}, #{e.message}")
      result[:msg] = e.message 
    end
    
    render :json => result
    
  end

  def update_customer

    result = ""
    cust_id = 0
    
    if params.has_key?(:cust_id) and not params[:cust_id].empty?
      cust_id = params[:cust_id].to_i
    end

    begin
      customer = Customer.find(cust_id)
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
    if params.has_key?(:cust_id) and not params[:cust_id].empty?
        customer = Customer.where("id = #{params[:cust_id]}").first
        unless customer.blank?
          customer_id = customer.id
        end        
    elsif params.has_key?(:cust_name) and not params[:cust_name].empty?
        customer = Customer.where("customer_name like '#{params[:cust_name]}'").first
        unless customer.blank?
          customer_id = customer.id
        end
    end

    render :layout => false, :text => customer_id
    
  end

  def list
    
    customers = []

    if params.has_key?(:cust_name) and not params[:cust_name].empty? and params[:cust_name].match(/^[[:alnum:]]+$/)
        p "dddddddddddddddd"
        log("dddd","dddddd",true,"aaaaaa")
        customers = Customer.where("customer_name like '#{params[:cust_name]}%'").all
        customers_temp = customers
        customers = []
        customers_temp.each { |c| customers << { :name => c.customer_name, :id => c.id } }
    end

    render :json => customers

  end

  def update_phones

    result_txt = "success"

    if params.has_key?(:cust_id) and not params[:cust_id].empty?
      if params.has_key?(:phones) and not params[:phones].empty?

        customer = Customer.where({:id => params[:cust_id]}).first

        unless customer.blank?

          if params.has_key?(:new_custn) and not params[:new_custn].empty?
            if params[:new_custn].strip != customer.customer_name
              log("Update","Customer",true)
              customer.update_attributes(:customer_name => params[:new_custn].strip)
            end
          end

          # clear all
          CustomerNumber.destroy_all(:customer_id => customer.id)

          log("Update","CustomerPhones",true,"customer_id:#{params[:cust_id]}")
          
          unless params[:phones] == "removeall"
            new_phone = (CGI::unescape(params[:phones])).split(',').compact
            new_phone = new_phone.uniq
            new_phone.each do |p|
              custn = CustomerNumber.new(
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

  def add_phone
    
    customer_name = params[:c]
    customer_phone_no = params[:p]

    if not customer_name.empty? and not customer_phone_no.empty?
      customer_phone_no = remove_phone_format(customer_phone_no)
      customer_phone_no = remove_nine_number_forp(customer_phone_no)
      c = Customer.where(:customer_name => customer_name).first
      unless c.nil?
        cn = CustomerNumber.where({:customer_id => c.id, :number => customer_phone_no }) 
        if cn.nil?
          CustomerNumber.create({:customer_id => c.id, :number => customer_phone_no })
        end
      end
    end
  
    render :json => { :result => true } 
    
  end

  def list_cars_by_voice
    
    voice_log_id = params[:voice_log_id].to_i
    car_nos = []
    
    if voice_log_id > 0
        vlcs = VoiceLogCar.where({:voice_log_id => voice_log_id})
        unless vlcs.empty?
          vlcs = vlcs.map { |x| x.car_number_id }
          cns = CarNumber.select("car_no").without_delete.where(:id => vlcs)
          unless cns.empty?
            car_nos = cns.map { |x| x.car_no }
          end
        end
    end

    render :json => {:cars => car_nos }

  end

  def list_phones
    
    phones = []

    if params.has_key?(:cust_id) and not params[:cust_id].empty?
      customer = Customer.where("id = '#{params[:cust_id]}'").first
    else
      customer = Customer.where("customer_name like '#{params[:cust_name]}'").first
    end
    
    unless customer.nil?
        phones = CustomerNumber.find_all_by_customer_id(customer.id)
        phone_temp = phones
        phones = []
        phone_temp.each { |p| phones << {:number => p.number } }      
    end

    render :json => phones

  end
  
  def profile
    
    customer_id = params[:id]
    customer_name = params[:name]
    
    c = Customer.where({:id => customer_id }).first
    
    unless c.nil?
      car_no = []
      if Aohs::MOD_CUST_CAR_ID
        car_no = CarNumber.select("car_no").without_delete.where({:customer_id => c.id }).group("car_no").all 
        car_no = car_no.map { |a| a.car_no }
      end
      cust = {:id => c.id, :name => c.customer_name, :car_no => car_no}
    else
      cust = false
    end
  
    render :json => cust
    
  end
  
  def autocomplete_list
    
    cust_name = params[:q]
    limit = params[:limit].to_i
    
    conditions = []
    unless cust_name.blank?
      conditions = "customer_name like '#{cust_name}%'"
    end
          
    customers = Customer.select('id,customer_name').where(conditions).order('customer_name asc').limit(limit).all
    
    render :text => (customers.map { |k| k.customer_name + "&break;(#{k.phone_list})&break;#{k.id}" }).join("\r\n")  
    
  end
  
  def update_calls
    
    customer_name = params[:name].strip
    customer_id = params[:id].to_i
    voice_log_id = params[:voice_log_id]
    cars_no = params[:car_no].to_s.strip
    
    phone = params[:phone]
    
    result = false
    
    if not customer_name.empty?
      # if exists?
      if customer_id > 0
        c = Customer.where(:id => customer_id, :customer_name => customer_name).first
        if c.nil?
          customer_id = 0
        end        
      end
      
      # if not exist? create new
      if customer_id <= 0
        c = Customer.new({:customer_name => customer_name})
        c.save!
        customer_id = c.id
      end
      
      # add new phone
      if not phone.nil? and not phone.empty?
        phone = remove_phone_format(phone).strip
        phone = remove_nine_number_forp(phone)
        cn = CustomerNumber.where({:customer_id => customer_id, :number => phone }).first 
        if cn.nil?
          CustomerNumber.create({:customer_id => customer_id, :number => phone })
        end     
      end
      
      #update car_no
      VoiceLogCar.delete_all({:voice_log_id => voice_log_id})
      unless cars_no.empty?
        # save car id
        cars_no = cars_no.split(",")
        cars_no.each do |crn|
          begin
            cn = CarNumber.where({:customer_id => customer_id, :car_no => crn}).first
            if cn.nil?
              cn = CarNumber.new({:customer_id => customer_id, :car_no => crn})
              cn.save!
            end
            voice_log_car = VoiceLogCar.new({:voice_log_id => voice_log_id, :car_number_id => cn.id })
            voice_log_car.save!
          rescue => e
            #
          end
        end
        # get new list car id
        vlcs = VoiceLogCar.where({:voice_log_id => voice_log_id})
        unless vlcs.empty?
          vlcs = vlcs.map { |x| x.car_number_id }
          cns = CarNumber.select("car_no").without_delete.where(:id => vlcs)
          unless cns.empty?
            cars_no = cns.map { |x| format_car_id(x.car_no) }
          else
            cars_no = []
          end
        end        
      end
      
    end
    
    v = VoiceLogTemp.where(:id => voice_log_id).first
    unless v.nil?
      v.update_customer_call(customer_id)
      result = true
    end
      
    render :json => {:result => result, :customer_id => customer_id, :customer_name => customer_name, :cars => cars_no }
    
  end
  
  def valid_customer_phone
  
    customer_name = params[:c]
    customer_id = params[:cid].to_i
    customer_phone_no = params[:p]
    
    phone_exist = false
    
    if not customer_name.empty? and not customer_phone_no.empty?  
      customer_phone_no = remove_phone_format(customer_phone_no)
      customer_phone_no = remove_nine_number_forp(customer_phone_no)
      c = Customer.includes(:customer_numbers).where({:customers => {:id => customer_id}, :customer_numbers => {:number => customer_phone_no }})
      unless c.empty?
        phone_exist = true
      end
    end
    
    STDOUT.puts "valid_customer_phone => #{phone_exist}"
    render :json => { :isphone_exist => phone_exist }
    
  end
  
end
