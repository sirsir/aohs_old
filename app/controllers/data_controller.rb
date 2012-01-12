class DataController < ApplicationController

  layout 'blank'

  before_filter :login_required

  include AmiSource
   
  def index

    redirect_to :action => 'import'
    
  end

  def import

    @upload_type = params[:q]
    
    @upload_format = "-"
    case @upload_type
      when 'keywords'
        @upload_format = "keyword's name*, keyword's type[Must,NG,Action]*, keyword group's name*"
      when 'users','Users'
        @upload_format = "agent_id, citizen_id, username*, full_name*, e-mail, group_name, sex*, role*, status*, expired_date"
      when 'customers'
        if Aohs::MOD_CUST_CAR_ID
          @upload_format = "customer's name*, phone, car id"
        else
          @upload_format = "customer's name*, phone1*, phone2, ... , phoneNx"
        end
      when 'dnis_agents'
        @upload_format = "DNIS(10), CTI Login(50), Team(50)"
      when 'extensions'
        @upload_format = "extension*, "
        @upload_format << "computer's name, ip address, " if Aohs::COMPUTER_EXTENSION_LOOKUP
        @upload_format << "phone number1,phone number2,phone numberN" if Aohs::CTI_EXTENSION_LOOKUP 
      else
        @upload_format = "Failed to check format!"
    end

  end
  
  def upload_file

    upload_cont = true
    up_fname = ""
    
    @replace_option = false
    
    case params[:q]
    when 'dnis_agents','extensions'
      @replace_option = true
    end
    
    begin

      if params.has_key?(:upload) and not params[:upload].empty?

        upload = params['upload']
        @upload_type = params[:q]

        @file_info = {:fname => nil}

        fname =  upload['datafile'].original_filename
        up_fname = fname
        @file_info[:fname] = fname

        @file_info[:fsize] = upload['datafile'].size ##File.size(upload['datafile'])
        if @file_info[:fsize] <= 0

          upload_cont = false
          flash[:uperror] = "upload file cannot empty size."
          
        else

          fext = File.extname(fname)

          if fext == ".csv"
            fname = "#{@upload_type.downcase}.csv"
          elsif fext == ".zip"
            fname = "data_upload.zip"
          else
            upload_cont = false
            flash[:uperror] = "upload file extension only *.csv or *.zip"
          end

          if upload_cont
            temp_directory = File.join(Rails.public_path,'temp') # "public/temp"
            if not File.directory?(temp_directory)
              Dir.mkdir(temp_directory)
            end

            if File.directory?(temp_directory)
              # clear diratory
              del_files = Dir.glob(File.join(temp_directory,'*.*'))
              del_files.each { |df| File.delete(df) }

              # create the file path
              path = File.join(temp_directory, fname)

              # write the file
              File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
            else
              flash[:uperror] = "temporary folder not found." 
            end

          end

        end    

      else
        #log("Upload","Data",false)
        upload_cont = false
        flash[:uperror] = "upload file cannot empty size."
      end

    rescue => e
      log("Upload","Data",false,e.message)
      flash[:uperror] = e.message
      upload_cont = false    
    end

    if not upload_cont
      redirect_to :action => 'import'
    else
      log("Upload","Data",true,"upload file: #{up_fname}")
    end
    
  end

  def upload_data
    
    txt = ""
    result = false
    
    begin
      replace = false
      replace = true if params[:replace] == 'true'

      update = false
      update = true if params[:update] == 'true'
      
      result, msg = import_data({:replace => replace,:update => update})
     
      if update == false
        txt = "Destination: #{msg[:file]}, Found: #{msg[:found]}, Added: #{msg[:new]}, Duplicate: #{msg[:dup]}, Error: #{msg[:error]}"
      else
        txt = "Destination: #{msg[:file]}, Found: #{msg[:found]}, Added: #{msg[:new]}, Updated: #{msg[:update]}, Skip update: #{msg[:skip]}, Error: #{msg[:error]}"
      end
      
      unless msg[:msg].empty?
        txt << ", Message: #{ msg[:msg].join(',') }"
      end
      
      log("Import","Data",true,txt)
         
      result = "true" if result
        
    rescue => e
      log("Import","Data",false,e.message)
      txt = e.message
    end

    render :json => {:result => result, :msg => txt}
          
  end
 
  def export

    @upload_type = params[:q]
    @upload_model = params[:m]

    data, fname = export_data({:table => @upload_type, :model => @upload_model})

    log("Export","Data",true,"target:#{@upload_type}")

    send_data data, {:filename => fname }
    
  end
  
end
