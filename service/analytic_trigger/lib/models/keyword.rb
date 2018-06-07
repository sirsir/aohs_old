class Keyword < ActiveRecord::Base

  serialize :notifiy_details, JSON
  
  def self.find_keyword(name)
    keyword = Keyword.where(name: name).first
    if not keyword.nil? and keyword.parent_id.to_i > 0
      parent_keyword = Keyword.where(id: keyword.parent_id).first
      unless parent_keyword.nil?
        keyword = parent_keyword
      end
    end
    return keyword
  end
  
  def self.create_message(keyword_p)
    keyword = find_keyword(keyword_p["keyword_name"])
    if not keyword.nil? and keyword.enabled_desktop_alert?
      content_data = {
        keyword: keyword_p["keyword_name"],
        keyword_type: keyword_p["keyword_type"],
        keyword_id: keyword.id,
        keyword_type_id: keyword.keyword_type_id
      }
      return content_data
    end
    return nil
  end

  def notify_details2
    if self.notify_details.is_a?(String)
      return JSON.parse(self.notify_details)
    end
    return self.notify_details
  end
  
  def keyword_type
    begin
      return KeywordType.where(id: self.keyword_type_id).first
    rescue
      return nil
    end
  end
  
  def enabled_desktop_alert?
    if not self.notify_flag == "N"
      if not keyword_type.nil? and keyword_type.notify_flag == "Y"
        return true
      end
    end
    return false
  end
  
  private
  
end
