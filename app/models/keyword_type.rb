class KeywordType < ActiveRecord::Base
  
  # default/initial word types
  WORD_TYPES = [
    { name: 'NG Word', description: 'Bad Words' },
    { name: 'Difficult Word', description: '' }
  ]
  
  has_many    :keywords
  
  has_paper_trail

  default_value_for   :flag, value: "", allows_nil: false

  serialize :notifiy_details, JSON
  
  validates   :name,
                presence: true,
                uniqueness: true,
                length: {
                  minimum: 2,
                  maximum: 50
                }
  
  scope :order_by_default, ->{
    order(name: :asc)  
  }
  
  def self.initialize_word_types
    WORD_TYPES.each do |type|
      wt = KeywordType.where(name: type[:name]).first
      if wt.nil?
        wt = KeywordType.new({ name: type[:name] })
      end
      wt.flag = DB_LOCKED_FLAG
      wt.description = type[:description]
      wt.save
    end
  end
  
  def self.update_new_type(name)
    type = where({ name: name }).first
    if type.nil?
      type = KeywordType.new({ name: name })
      type.save
    end
    return type
  end
  
  def self.type_options  
    order("name").all.map { |o| [o.name,o.id] }
  end
  
  def keywords_count
    return self.keywords.not_deleted.count(0)
  end
  
  def enabled_desktop_notification?
    return yes_or_true?(self.notify_details2["desktop_alert"])
  end
  
  def enabled_sound_alert?
    return yes_or_true?(self.notify_details2["desktop_sound"])
  end
  
  def cc_leader?
    return yes_or_true?(self.notify_details2["cc_leader"])
  end
  
  def update_notification_setting(data)
    self.notify_flag = "N"
    if yes_or_true?(data["desktop_alert"])
      self.notify_flag = "Y"
    end
    self.notify_details = data.to_json
  end
  
  def notify_details2
    begin
      return JSON.parse(self.notify_details)
    rescue
    end
    return {}
  end
  
  private
  
  def yes_or_true?(str)
    return ((str == "yes") or (str == "true") or (str == "y"))
  end
  
end
