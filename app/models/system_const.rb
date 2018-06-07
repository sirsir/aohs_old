class SystemConst < ActiveRecord::Base
  
  scope :find_const, ->(cate){
    where(cate: cate)
  }
  
  scope :find_value, ->(cate,code){
    find_const(cate).where(code: code)  
  }
  
  scope :namecode_start_with, ->(txt){
    conds = []
    unless txt.is_a?(Array)
      txt = [txt]
    end
    conds = txt.uniq.map { |t| "code LIKE '#{t}%' OR name LIKE '#{t}%'" }
    where(conds.join(" OR "))
  }
  
  scope :sex, -> {
    where(cate: [':sex', 'sex'])
  }
  
  scope :user_state, -> {
    where(cate: [':ustate', 'ustate'])
  }
  
  scope :log_types, -> {
    where(cate: [':log-types', 'log-types'])
  }
    
  scope :name_title, -> {
    where(cate: 'name-title')
  }
  
  scope :speaker, -> {
    where(cate: 'speaker_type')
  }

  scope :landing_page, -> {
    where(cate: 'landing-page')
  }
  
  scope :edu_degree, ->(p=nil){
    unless p.nil?
      where(cate: 'edu-degree', code: p)
    else
      where(cate: 'edu-degree')
    end
  }

  scope :group_types, ->(){
    where(cate: 'group_types')  
  }
  
  scope :log_events,  -> {
    where(cate: ':log-events')
  }
  
  scope :file_types,  -> {
    where(cate: ':file-types')
  }
  
  scope :call_type, -> { find_const('call-type') }
  scope :call_direction, -> { find_const('call_direction') }
  scope :notification_level, -> { find_const('notify_level') }
  
  def self.options_for(name, options={})
    
    #
    # return list options for select box
    # format: [[name,code], ..., [..., ...]]
    #
    
    list = find_const(name).all
    list = to_select_options(list, options)
    
    return list
  end
  
  def self.sex_options  
    return to_select_options(sex)
  end

  def self.notification_level_options(options={})
    opts = to_select_options(notification_level)
    if options[:include_disabled] == true
      opts.insert(0,["None (Disabled)", "none"])
    end
    return opts 
  end
  
  def self.nametitle_options
    return to_select_options(name_title)
  end

  def self.log_type_options  
    return to_select_options(log_types)
  end
  
  def self.log_events_options  
    return to_select_options(log_events)
  end

  def self.speaker_options  
    return to_select_options(speaker)
  end
  
  def self.call_direction_options
    return to_select_options(call_direction)
  end
  
  def self.landing_page_options
    return to_select_options(landing_page)
  end
  
  def self.group_type_options
    return to_select_options(group_types)
  end
  
  def self.filetype_options(fext=[]) 
    selected_types = file_types.order("name")
    unless fext.empty?
      selected_types = selected_types.where(code: fext)  
    end
    return selected_types.all.map { |o| [o.name,o.code] }
  end

  def self.user_state_options(is_admin=false)
    states = user_state
    unless is_admin
      states = states.where.not({code: STATE_DELETE})  
    end
    return states.order("name").all.map { |o| [o.name,o.code] }
  end

  def self.notification_timeout_options
    return [['3 seconds',3],['5 seconds',5],['10 seconds',10],['15 seconds',15]]  
  end
  
  def self.audio_filetypes
    aftypes = []
    aftypes << { text: 'WAVE Audio File', file_extension: '.wav', file_type: 'wav' }
    aftypes << { text: 'MP3 Audio File', file_extension: '.mp3', file_type: 'mp3' }
    aftypes << { text: 'Ogg Vorbis Speex File', file_extension: '.spx', file_type: 'spx' }
    return aftypes
  end
  
  def self.update_list(type_name, list, force_clear=false)
    nlist = []
    bs = {
      cate: type_name
    }
    list.each do |l|
      next if l[:code].nil?
      ra = where(bs).where({ code: l[:code] }).first
      if ra.nil?
        ra = new(l)
        ra.cate = type_name
      else
        ra.name = l[:name]
      end
      ra.save
      nlist << ra.code
    end
    if force_clear
      dlist = where(bs).where.not(code: nlist)
      dlist.delete_all
    end
  end
  
  private
  
  def self.to_select_options(data, options={})
    if options[:show_code] == true
      return data.order("code").all.map { |o| [[o.code,o.name].join(" : "), o.code] }
    end  
    return data.order("name").all.map { |o| [o.name, o.code] }
  end
  
end
