require 'csv'

class ImportBase
  
  def initialize(input_file, opts={})
  
    @errors   = []
    @info     = []
    @msgs     = []
    @fpath    = input_file
    @ds       = []
    @counter  = {
      found: 0,
      total: 0,
      error: 0,
      added: 0,
      updated: 0,
      skip: 0,
      deleted: 0,
      tt: Time.now
    }
    @opts     = opts
              # opts ::
              # update_if_exist = true|false
    
    if correct_file? and valid_options?
      load_data
    end

  end
  
  def load_data
    
    ds = get_csv_data
    init_headers(ds)
    if correct_headers?
      init_data(ds)
    end
  
  end

  def init_headers(ds)
    
    @cols = []
    ds.headers.each do |h|
      @cols.push(map_colname_x(h))
    end

  end
  
  def init_data(ds)
    
    rows = ds.to_a
    rows.shift
    
    rows.each_with_index do |row,i|
      @ds << row_info(to_rec(row))
      @counter[:found] += 1
    end
    
  end

  def to_rec(row)
    
    rec = {}
    row.each_with_index do |rx,j|
      next if rx.nil?
      rec[@cols[j]] = rx unless @cols[j] == false
    end

    return rec
    
  end
  
  def map_colname_x(col_name)
    
    rs = map_colname(col_name)
    
    if rs == false
      info "Column \'#{col_name}\', this will be skiped."
    else
      info "Column \'#{col_name}\'"
    end
    
    return rs
        
  end
  
  def correct_headers_info_x?
    
    unless correct_headers_info?
      errors "No required columns or misspelling."
      return false
    end
    
    return true
  
  end
  
  def data
    
    return @ds
  
  end
  
  def update(opts={})
    
    update_data unless @ds.empty?
  
  end

  def update_data
    
    @ds.each_with_index do |rec,i|
      
      @counter[:total] += 1
      
      if rec[:errors].empty?
        rec = insert_or_update(rec)
      end
      
      unless rec[:errors].empty?
        @counter[:error] += 1
        errors "Line #{i+1} :" + rec[:errors].join(", ")
      else
        if require_update?
          if rec[:new_record]
            @counter[:added] += 1
          else
            @counter[:updated] += 1
          end
        else
          @counter[:skip] += 1
        end
      end
      
    end
  
  end
    
  def get_csv_data
    
    CSV.parse(File.read(@fpath), :headers => true)
    
  end

  def row_info(rec)
  
    rec[:errors] = []
    
    if rec[:login_name].present?
      user = User.only_active.where(login: rec[:login_name]).first
      unless user.nil?
        rec[:user_id] = user.id
        rec[:group_id] = user.group_member.group_id
      end
    end
    
    if rec[:role_name].present?
      role = Role.not_deleted.where(name: rec[:role_name]).first
      unless role.nil?
        rec[:role_id] = role.id
      else
        rec[:errors] << "Role does not exist"
      end
    end
    
    if rec[:group_name].present?
      group = Group.where(short_name: rec[:group_name]).first
      unless group.nil?
        rec[:group_id] = group.id
      else
        rec[:errors] << "Group does not exist"
      end
    end
    
    if rec[:sex_name].present?
      sex = rec[:sex_name].downcase
      if ['m','male','f','female','u','undefined'].include?(sex)
        rec[:sex_code] = sex[0].downcase
      else
        rec[:errors] << "Sex is invalid"
      end
    end
    
    return rec
    
  end

  def correct_headers?
    
    if @cols.count(false) == @cols.count
      errors "Not found columns at the first line or invalid patterns."
      return false
    end
    
    return correct_headers_info_x?
    
  end
  
  def correct_file?
    
    unless File.exists?(@fpath)
      errors "File does not exist on the system or incorrect file format."
      return false
    end
    
    return true
  
  end
  
  def valid_options?
    
    if @opts[:update_if_exist].present?
      info "Option: update if exist ... #{(require_update? ? "yes" : "no")}"
    else
      @opts[:update_if_exist] = false
    end
    
  end
  
  def require_update?
  
    return (@opts[:update_if_exist] == true or @opts[:update_if_exist] == "true")
  
  end
  
  def errors(msg=nil)
    
    if msg.nil?
      @errors
    else
      STDOUT.puts "[#{self.class.name}] #{msg} (error)"
      @errors << msg
      @msgs << msg
    end
    
  end
  
  def results
    
    msgs = [
      "Import file finished."
    ]
    
    msgs << [
      "Found: #{@counter[:found]} records",
      "Total: #{@counter[:total]} records",
      "Added: #{@counter[:added]} records",
      "Updated: #{@counter[:updated]} records",
      "Deleted: #{@counter[:deleted]} records",
      "Error: #{@counter[:error]} records",
      "Skip: #{@counter[:skip]} records"
    ].join(", ")
    
    @counter[:tt] = Time.now - @counter[:tt]
    msgs << "Update completed in #{@counter[:tt]} secs"
    msgs << ""
    
    unless @errors.empty?
      msgs << "The update was not successfully. please check log to see problems."
    else
      msgs << "The update was successfully."
    end
    
    return {
      counter: @counter,
      messages: msgs.concat(@errors)
    }
  
  end
  
  def info(msg=nil)
    
    if msg.nil?
      @info
    else
      STDOUT.puts "[#{self.class.name}] #{msg}"
      @info << msg
      @msgs << msg
    end
    
  end
  
end