class Keyword < ActiveRecord::Base
  
  MAX_INPUT = 2
  MAX_NOTIFY_CONTENT = 3
  PARENT_ID = 0
  
  has_many    :childrens, class_name: "Keyword", foreign_key: "parent_id"
  belongs_to  :parent, class_name: "Keyword"
  belongs_to  :keyword_type
  
  has_paper_trail
  
  strip_attributes  only: [:name]
  
  serialize :notifiy_details, JSON
  serialize :detection_settings, JSON
  
  default_value_for :parent_id, value: 0, allows_nil: false
  
  validates :name,
              presence: true,
              uniqueness: true,
              length: {
                minimum: 2,
                maximum: 100
              }

  validates :keyword_type,
              presence: true

  scope :not_deleted, -> {
    where.not({flag: DB_DELETED_FLAG})
  }
  
  scope :root, ->{
    where({ parent_id: PARENT_ID })  
  }
  
  scope :not_root, ->{
    where.not({ parent_id: PARENT_ID })
  }
  
  scope :only_ngword, ->{
    where(subtype: ['n'])
  }
  
  scope :order_by, ->(p) {
    incs = []
    order_str = resolve_column_name(p)
    includes(incs).order(order_str)
  }
  
  scope :keyword_type_eq, ->(n){
    c_name = "keyword_types.name"
    if n =~ /^[0-9]+/
      c_name = "keyword_types.id"
    end
    where("EXISTS (SELECT 1 FROM keyword_types WHERE #{c_name} = '#{n}' AND keywords.keyword_type_id = keyword_types.id)")
  }
  
  def self.to_setting_data(keywords)
    list = []
    keywords.each do |keyword|
      l = {
        keyword: keyword.name,
        keyword_id: keyword.id,
        keyword_parent: keyword.parent_keyword_name,
        keyword_parent_id: keyword.parent_keyword_id,
        keyword_group: keyword.keyword_type.name,
        type: keyword.subtype.to_s,
        settings: keyword.detection_settings2
      }
      list << l
    end
    return list
  end
  
  def self.replace_a_tag(str)
    # remove a tag from html string
    unless str.nil?
      str = str.gsub(/<a href=(['"].+['"])>([^<]+?)/mi,'<span x-href=\1>\2')
      str = str.gsub(/<a .*?>([^<]+?)/mi,'<span>\1')
      str = str.gsub(/<a>([^<]+?)/mi,'<span>\1')
      str = str.gsub(/<\/a\s*>/mi,'</span>')
    end
    return str
  end

  def self.replace_script_tag(str)
    # remove script tag from html string
    unless str.nil?    
      str = str.gsub(/<script ?.*?>(.+?)<\/script>/mi,'<span>\1</span>')
      str = str.gsub(/<script ?.*?>(.+?)<\/.*?>/mi,'<span>\1</span>')
      str = str.gsub(/<script ?.*?>([^<]*)$/mi,'<span>\1</span>')
    end
    return str
  end

  def self.replace_tag(str)
    # remove tags from html string
    str = replace_a_tag(str)
    str = replace_script_tag(str)
    return str
  end

  def notification_default?
    return (not self.notify_flag == "N")
  end
  
  def disabled_notification?
    return (self.notify_flag == "N")
  end
  
  def notification_template
    contents = notify_details2["contents"]
    contents = [] if contents.blank?
    return contents
  end
  
  def notification_level_icon_name
    if disabled_notification?
      return "none"
    else
      if notification_default?
        if (not self.keyword_type.nil?) and self.keyword_type.enabled_desktop_notification?
          return "bell-o"
        end
      end
    end
    return "none"
  end
  
  def word_list_form
    
    list = []
    words = self.childrens.all
    word_count = words.count
    
    words.each do |w|
      list << { id: w.id, text: w.name }
    end
    
    i = 0
    while i < MAX_INPUT - word_count
      list << { id: 0, text: "" }
      i += 1
    end
    
    return list
  
  end

  def update_word_list(list)
    
    @words_error = []
    updated_id = [0]
    
    # update word list
    unless list.empty?
      list.each do |word|
        next if word.empty?
        k = Keyword.where({ name: word }).not_root.first
        if k.nil?
          k = Keyword.new
        end
        k.name = word
        k.keyword_type_id = self.keyword_type_id
        k.bg_color = self.bg_color
        k.parent_id = self.id
        if k.save
          updated_id << k.id
        else
          @words_error << { id: 0, text: word, error_message: 'already taken or invalid'}
        end
      end
    end
    
    # remove no update
    Keyword.where({ parent_id: self.id }).where.not({ id: updated_id }).delete_all
    
    return @words_error.empty?
  
  end
  
  def words_error
    ((defined? @words_error) ? @words_error : []) 
  end
  
  def do_delete  
    self.flag = DB_DELETED_FLAG
    self.childrens.all.each do |w|
      w.flag = DB_DELETED_FLAG
      w.save
    end 
  end
  
  def can_delete?
    true
  end
  
  def css_content_class
    return "content-keyword-#{self.id}"
  end

  def fg_color_auto
    return AppUtils::ColorTool.oposite_color(self.bg_color)
  end
  
  def parent_keyword_name
    if self.parent_id.to_i > 0
      p = self.parent
      unless p.nil?
        return p.name
      end
    end
    return self.name
  end
  
  def parent_keyword_id
    if self.parent_id.to_i > 0
      p = self.parent
      unless p.nil?
        return p.id
      end
    end
    return self.id
  end

  def notify_details2
    begin
      return JSON.parse(self.notify_details)
    rescue
    end
    return {}
  end
  
  def detection_settings2
    begin
      return JSON.parse(self.detection_settings)
    rescue
    end
  end
  
  private

  def self.ransackable_scopes(auth_object = nil)
    %i(keyword_type_eq)
  end
  
  def self.resolve_column_name(str)
    str
  end
  
end
