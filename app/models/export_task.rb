require 'securerandom'

class ExportTask < ActiveRecord::Base
  
  # Export Flag (state)
  # 'W' = Wait for processing
  # 'S' = Success/Finished/Done
  # 'X' = Exporting
  # 'F' = Failed/Unsuccess
  # 'D' = Delete
  
  PATH_PATTS = [
    "<CALL-DATE>",
    "<CALL-TIME>",
    "<CALL-DATETIME>",
    "<EXTENSION>",
    "<CALLID>",
    "<DIRECTION>",
    "<ANI>",
    "<DNIS>",
    "<AGENT-NAME>",
    "<RANDSTR>"
  ]
  
  SCHEDULE_TYPE = [
    { code: :adhoc,   title: "Ad Hoc" },
    { code: :daily,   title: "Daily"  }
  ]
  
  default_value_for   :filename,  Settings.callexport.default_path
  
  has_many    :export_conditions
  has_many    :export_logs
  
  strip_attributes    allow_empty: true,
                      collapse_spaces: true

  validates   :name,  presence: true,
                      uniqueness: true,
                      length: {
                        minimum: 2,
                        maximum: 50
                      }

  validates   :category,  presence: true,
                      length: {
                        minimum: 2,
                        maximum: 30
                      }

  validates   :filename,  presence: true,
                      allow_empty: nil,
                      length: {
                        minimum: 2,
                        maximum: 100
                      },
                      if: :correct_name_pattern?

  scope  :only_wait, ->{
    where({ flag: 'W' }) 
  }
  
  scope :adhoc_task, ->{
    where({ schedule_type: 'adhoc' })  
  }

  scope :daily_task, ->{
    where({ schedule_type: 'daily' })  
  }
  
  scope :not_deleted, ->{
    where.not({ flag: 'D' })  
  }
  
  scope :not_exporting, ->{
    where.not({ flag: 'X' })  
  }
  
  scope :only_exporting, ->{
    where({ flag: 'X' })
  }
  
  scope :order_by, ->(p) {
    
    incs      = []
    order_str = resolve_column_name(p)
    
    includes(incs).order(order_str)
    
  }
  
  def self.schedule_type_options
    types = SCHEDULE_TYPE.map { |s| [s[:title], s[:code]] }
    return types
  end
  
  def type_name
    self.schedule_type.capitalize
  end
  
  def directory_name
    return self.name.gsub(/[^\w\.]/,"_")
  end
  
  def audio_format_sym
    return self.audio_type.downcase.to_sym
  end
  
  def last_processed_date
    self.export_logs.maximum(:updated_at)
  end

  def adhoc?
    return self.schedule_type == "adhoc"
  end
  
  def daily?
    return self.schedule_type == "daily"
  end
  
  def wait_for_process?
    return self.flag == "W"
  end
  
  def in_progress?
    return (self.flag == "X" or self.flag == "D")
  end
  
  def finished?
    return self.flag == "S"
  end
  
  def failure?
    return self.flag == "F"
  end
  
  def finish_or_failure?
    return (finished? or failure?)
  end
  
  def expired?
    expiry_day = 3
    if Settings.callexport.expiry_day_in.to_i > 0
      expiry_day = Settings.callexport.expiry_day_in.to_i
    end
    unless self.processed_at.nil?
      if (Time.now - self.processed_at.beginning_of_day)/86400.0 > expiry_day
        return true
      end
    end
    return false
  end
  
  def deleted?
    return self.flag == "D"
  end

  def not_ready?
    return self.flag == "N"
  end

  def state_name
    
    case self.flag
    when 'N'
      "Not Ready"
    when 'W'
      "Wait"
    when 'X'
      "Exporting"
    when 'F'
      "Failed"
    when 'D'
      "Delete"
    else
      "Done"
    end
  
  end
  
  def set_state(s=:new)
    case s
    when :new, :not_ready
      self.flag = 'N'
    when :wait, :ready
      self.flag = 'W'
    when :delete
      self.flag = 'D'
    end
    
  end
  
  def set_state_processing
    unless self.flag == "D"
      self.flag = "X"
      save
    end
  end
  
  def set_state_finish(s)
    unless self.flag == "D"
      case s
      when :completed, :complete
        self.flag = "S"
      when :wait
        self.flag = "W"
      when :error, :failed
        self.flag = "F"
      else
        # default/recovery
        self.flag = "W"
      end
      save
    end
  end
  
  def do_delete
    set_state(:delete)
  end
  
  def do_permanent_delete
    self.export_conditions.delete
    self.export_logs.delete
  end
  
  def update_conditions(conds)
  
    # remove old and update new
    self.export_conditions.all.map { |ex| ex.delete }
    
    conds.each do |cond|
      ex = self.export_conditions.new
      ex.condition_string = cond
      ex.save
    end
    
    if conds.length > 0
      set_state(:ready)
    else
      set_state(:not_ready)
    end
    
  end
  
  def get_conditions_string
    
    h_conds = []
    conds = self.export_conditions.all
    conds.each_with_index do |cond, i|
      cond["id"] = i
      h_conds << cond.condition_string
    end
    
    return h_conds.to_json
  
  end
  
  def map_filename(voicelog)
    
    call_date = voicelog["start_time"].strftime("%Y%m%d")
    call_time = voicelog["start_time"].strftime("%H%M%S")
    call_datm = voicelog["start_time"].strftime("%Y%m%d_%H%M%S")
    ext       = (voicelog["extension"].blank? ? "0000" : voicelog["extension"])
    ani       = voicelog["ani"].to_s
    dnis      = voicelog["dnis"].to_s
    call_id   = voicelog["call_id"].to_s
    cd        = voicelog["call_direction"].to_s
    name      = voicelog["login"].to_s
    rndstr    = SecureRandom.hex(5)

    fname = self.filename
    fname = fname.gsub("<CALL-DATE>", call_date)
    fname = fname.gsub("<CALL-TIME>", call_time)
    fname = fname.gsub("<CALL-DATETIME>", call_datm)
    fname = fname.gsub("<EXTENSION>", ext)
    fname = fname.gsub("<DIRECTION>", cd)
    fname = fname.gsub("<CALLID>", call_id)
    fname = fname.gsub("<ANI>", ani)
    fname = fname.gsub("<DNIS>", dnis)
    fname = fname.gsub("<AGENT-NAME>", name)
    fname = fname.gsub("<RANDSTR>", rndstr)
    
    return fname
  
  end

  def log_fname
    return "export_#{sprintf('%08d',self.id)}.log"
  end
  
  def compression_method
  
    case self.compression_type.downcase
    when "7-zip", "7z"
      return "7zip"
    when "gzip", "tar.gz", "gz"
      return "gz"
    when "bzip2", "tar.bz2", "bz2"
      return "bz2"
    when "tar"
      return "tar"
    when "zip"
      return "zip"
    end

    return false
  
  end
  
  def get_file_list
    
    dirs = []
    
    path = File.join(Settings.server.directory.call_export, self.name)
    
    res = Dir.glob(File.join(path,"*.*"))
    res.each do |r|
      dirs << {
        fname: File.basename(r),
        fsize: File.size(r),
        mtime: File.mtime(r),
        shared_url: r.gsub(Settings.server.directory.public,Settings.server.docroot)
      }
    end
    
    return dirs
  
  end
  
  def log_exist_and_success?(hc)
    
    wh = {
      export_task_id: self.id,
      digest_string: hc
    }
    
    cnt = ExportLog.where(wh).only_success.count
    
    return (cnt > 0)
  
  end
  
  private

  def correct_name_pattern?
    
    path = filename.to_s
    parm_count = 0
    
    # check parms
    while va = path.match(/(<[a-zA-z-]+>)/) and parm_count <= 20
      v = va.to_s
      path = path.gsub(v,"X")
      unless PATH_PATTS.include?(v)
        errors.add(:filename, "#{v} is wrong")
      end
      parm_count += 1
    end
    
    # path pattern  
    if not path.match(/[^\/\-_a-zA-Z0-9]/).nil? or not path.match(/\/{2,}/).nil? or not path.match(/^(\/).+\z/).nil? or not path.match(/^.+(\/)\z/).nil?
      errors.add(:filename, "is invalid path")
    end
    
    return true
  
  end
  
  def self.resolve_column_name(str)
    
    unless str.empty?
      
      if str.match(/(title)/)
        str = str.gsub("title","export_tasks.name")
      end

      if str.match(/(status)/)
        str = str.gsub("status","export_tasks.flag")
      end

      if str.match(/(type)/)
        str = str.gsub("type","export_tasks.schedule_type")
      end

      if str.match(/(last_export_date)/)
        str = str.gsub("last_export_date","export_tasks.processed_at")
      end
      
    end
    
    str
    
  end
  
end
