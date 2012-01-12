class ExtensionController < ApplicationController

  require 'csv'
  layout 'control_panel'
  
  before_filter :login_required
  before_filter :permission_require

  def index

      conditions = []
  
      sort_key = nil
      # check sort key
      case params[:col]
      when /ext/:
         sort_key = 'extensions.number'              
      else
         sort_key = 'extensions.number'
      end
      
      order = "#{sort_key} #{check_order_name(params[:sort])}" 
                  
      if params.has_key?(:user) and not params[:user].empty?
        conditions << "login like '%#{params[:user]}%'"
      end
      if params.has_key?(:agent_id) and not params[:agent_id].empty?
        conditions << "cti_agent_id like '#{params[:agent_id]}%'"
      end
       
      unless conditions.empty?
        usrs = User.find(:all,:conditions => conditions.join(" and "))
        if usrs.empty?
          conditions = false
        else
          exts = ExtensionToAgentMap.find(:all,:conditions => {:agent_id => usrs.map { |u| u.id } },:group => 'agent_id')
          if exts.empty?
            conditions = false
          else
            conditions = []
            conditions << "extensions.number in (#{ (exts.map { |t| "'#{t.extension}'"}).join(',')})"
          end
        end

      end
          
      if conditions == false
        conditions = []
        conditions << "extensions.number is null"
      end
      
      if params.has_key?(:ext) and not params[:ext].strip.empty?
        conditions << "extensions.number like '%#{params[:ext].strip}%'"
      end
      
      if params.has_key?(:dids) and not params[:dids].strip.empty?
        conditions << "dids.number like '%#{params[:dids].strip}%'"
      end
      
      @extension = Extension.paginate(
          :page => params[:page],
          :per_page => $PER_PAGE,
          :include => [:dids],
          :conditions => conditions.join(' and '),
          :order => order, 
          :group => 'extensions.number')

  end

  def edit

    begin
        @extension = Extension.find(params[:id])
    rescue => e
        log("Edit","PhoneExtension",false,"id:#{params[:id]},#{e.message}")
        redirect_to :controller => 'extension',:action => 'index'
    end

  end

  def edit_did
    begin
     @did = Did.find(params[:id])
    rescue => e
      log("Edit","PhoneExtension:DID",false,"id:#{params[:id]},#{e.message}")
      redirect_to :controller => 'extension',:action => 'index'
    end
  end

  def new_did
    @did = Did.new
  end

  def show
      begin
        @extension = Extension.find(params[:id])
      rescue => e
        log("Show","PhoneExtension",false,"id:#{params[:id]},#{e.message}")
        redirect_to :controller => 'extension',:action => 'index'
      end
  end

  def update
      begin
        @extension = Extension.find(params[:id])
        if @extension.update_attributes(params[:extension]) and not @extension.number.blank?
           log("Update","PhoneExtension",true,"id:#{params[:id]},ext:#{@extension.number}")
        else
           flash[:message] = "Update extension fail."
           log("Update","PhoneExtension",false,"id:#{params[:id]}")
        end
      rescue => e
         flash[:message] = "Update extension fail."
         log("Update","PhoneExtension",false,"id:#{params[:id]},#{e.message}")
      end
      
      redirect_to :action => 'edit',:id => @extension.id
  end

  def new
     @extension = Extension.new
  end

  def create
    @extension = Extension.new(params[:extension])

    if @extension.save and not @extension.number.blank?
      log("Add","PhoneExtension",true,"ext:#{@extension.number}")
      redirect_to :controller => 'extension',:action => 'index'
    else
      log("Add","PhoneExtension",false,"ext:#{@extension.number}")
      flash[:message] = 'Extension number couldn\'t be null.'
      redirect_to :controller => 'extension',:action => 'new'
    end
  end

  def delete
    @extension = Extension.find(params[:id])
    number = @extension.number
    if @extension.destroy()
       log("Delete","PhoneExtension",true,"ext:#{number}")
      # flash[:notice] = 'Delete Extension successfully.'
    else
       log("Delete","PhoneExtension",false,"ext:#{number}")
       flash[:message] = 'Delete Extension failed.'
    end
     redirect_to :action => 'index'
  end

  def delete_did
    @did = Did.find(params[:id])
    rid = @did.extension_id
    d_num = @did.number
    if @did.destroy()
       log("Delete","PhoneExtension:DID",true)
    else
       flash[:message] = "can't not delete dids."
       log("Delete","PhoneExtension:DID",false)
    end
    redirect_to :action => 'edit',:id => rid
  end

  def add_dids
    begin
    @did = Did.new(params[:dids])
    rid = @did.extension_id
    unless Did.exists?({:number =>@did.number,:extension_id => @did.extension_id})
      if @did.save
        log("Add","PhoneExtension:DID",true)
        redirect_to :action => 'edit',:id => @did.extension_id
     else
        flash[:message] = "Add did number failed."
        log("Add","PhoneExtension:DID",false)
        redirect_to :action => 'new_did',:ext_id => @did.extension_id
      end
    else
       flash[:message] = "Add did number failed."
       log("Add","PhoneExtension:DID",false,"this did number already exits in extension map.")
       redirect_to :action => 'new_did',:ext_id => @did.extension_id
    end
    rescue => ex
      flash[:message] = "Add did number fail. see log."
      log("Add","PhoneExtension:DID",false)
      redirect_to :action => 'new_did',:ext_id => rid
    end
  end

  def update_did
     begin
        @did = Did.find(params[:id])
        if @did.update_attributes(params[:did]) and not @did.number.blank?
          # flash[:notice] = "Update did number complete."
           log("Update","PhoneExtension:DID",true)
        else
           flash[:message] = "Update extension fail."
           log("Delete","PhoneExtension:DID",false)
        end
      rescue => e
         flash[:message] = "Updaate did fail. please see log for more details."
         log("Delete","PhoneExtension:DID",true,e.message)
      end
      redirect_to :action => 'edit',:id => @did.extension_id
  end

  def export
      begin
           file_name = "extensions.csv"
           @extension = Extension.find(:all,:order => 'id')
           exportfile = StringIO.new
           CSV::Writer.generate(exportfile,",") do |title|
             mcols = Did.find_by_sql("SELECT MAX(m) AS cols FROM (SELECT COUNT(id) AS m FROM dids GROUP BY extension_id) i")
             max_did = mcols[0].cols.to_i
             STDERR.puts 'MX = '+max_did.to_s
             head = []
             head << "extension_number"
             unless max_did.blank?
                (1..max_did).each do |i|
                  head << "DID#{i}"
                end
             end
             title << head
             @extension.each_with_index do |ext,i|
             details = []
             details << ext.number
             unless ext.dids.blank?
               r_row = 0
               ext.dids.each do |dn|
                  details << dn.number
                  r_row += 1
               end 
               if r_row < max_did
                 (1..(max_did - r_row)).each() { |e| details << nil }
               end
             else
              (1..max_did).each do |i|
               details << nil
               end
             end
             title << details
             end
      end
      exportfile.rewind
      log("Export",file_name,true)
      send_data(exportfile.read,:type => 'text/csv; charset=iso-8859-1; header=present',:filename =>file_name, :disposition =>'attachment', :encoding => 'utf8')
      rescue => ex
      log("Export","-",false,ex.message)
      flash[:message] = "export fail. see log for more detail."
      redirect_to :action => 'index'
      end
  end

  def import
    
  end

  def csv_import
    
  result = {:found => 0, :add => 0, :del => 0, :update => 0, :error => 0}  
    
  begin
    filename = "<unknownFile>"
    unless params[:imoption].blank? or not params.has_key?(:imoption)
      if params[:imoption] == 'r'
         result[:del] = Extension.count(:id).to_i
         Extension.delete_all()
         Extension.connection.execute("ALTER TABLE #{Extension.table_name} AUTO_INCREMENT = 1")
         Did.delete_all()
         Did.connection.execute("ALTER TABLE #{Did.table_name} AUTO_INCREMENT = 1")
        # STDERR.puts 'delete all'
      end
      filename = params[:dump][:file].original_filename
        
      @parsed_file=CSV::Reader.parse(params[:dump][:file])
      n = 0
      @parsed_file.each_with_index  do |row,inx|
          unless row[0].to_i == 0
             # STDERR.puts 'row no. '+inx.to_s
            if Extension.exists?(:number => row[0])   
              result[:update] += 1            
               #STDERR.puts 'length '+row.length.to_s
               (1..(row.length - 1)).each do |c|
                  #STDERR.puts c
                  #STDERR.puts row[c]
  #               STDERR.puts row[c] != "-"
                 unless row[c] == "-" || row[c].blank?
                  if Did.exists?(:number => row[c])
                     dn = Did.find(:first,:conditions =>{:number => row[c]})
                     dn.update_attribute(:extension_id,
                     Extension.find(:first,:conditions =>{:number => row[0]}).id)
                  else
                    dn = Did.new(:number => row[c],:extension_id => Extension.find(:first,
                    :conditions =>{:number => row[0]}).id)
                    dn.save!
                  end
                 end
               end
            else
               tmpext = Extension.new(:number => row[0])
               if tmpext.save!
                 result[:add] += 1
                  (1..(row.length - 1)).each do |c|
                    unless row[c] == "-" || row[c].blank?
                    if Did.exists?({:number => row[c]})
                       dn = Did.find(:first,:conditions =>{:number => row[c]})
                       dn.update_attribute(:extension_id,tmpext.id)
                    else
                       dn = Did.new(:number => row[c],:extension_id =>tmpext.id)
                       dn.save!
                    end
                    end
                   end
               else
                  result[:error] += 1 
               end
            end
            n=n+1
            GC.start if n%50==0
         end
      end
      msg = "File:#{filename} , Added: #{result[:add]}, Updated: #{result[:update]}, Deleted: #{result[:del]}, Error: #{result[:error]}"
      log("Import","PhoneExtension",true,msg)
      # flash[:mess] = "Import data complete."
      redirect_to :action => 'index'
    else
      log("Import","PhoneExtension",false,"option invalid.")
      flash[:message] = "Import data has been failed! import option invalid"
      redirect_to :action => 'import'
    end
  rescue => ex
      STDERR.puts ex.message
      STDERR.puts ex.backtrace
      log('Import',"PhoneExtension",false,ex.message)
      flash[:message] = "Import data has been failed! please see log for details."
      redirect_to :action => 'import'
  end
  end
  
  def result
    
    sql =  "select u.login,u.cti_agent_id,m.extension as extension,m.dids as numbers,c.check_time,c.remote_ip from "
    sql << "(select id,login,cti_agent_id from users where flag != 1) u "
    sql << "left join "
    sql << "(select e.agent_id,e.extension,group_concat(d.number) as dids "
    sql << "from extension_to_agent_maps e left join did_agent_maps d on e.agent_id = d.agent_id "
    sql << "group by e.agent_id,e.extension) m " 
    sql << "on u.id = m.agent_id "
    sql << "left join "
    sql << "(select c.check_time,c.agent_id,remote_ip from current_watcher_status c where date(check_time) = date(now())) c "
    sql << "on u.id = c.agent_id "
    #sql << "where u.cti_agent_id is not null and u.cti_agent_id > 0 "
    sql << "order by u.cti_agent_id "
    
    @res = Extension.find_by_sql(sql)
    
    render :layout => 'blank'
    
  end
end
