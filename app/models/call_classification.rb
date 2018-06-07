class CallClassification < ActiveRecord::Base

  belongs_to    :voice_log
  belongs_to    :call_category
  
  scope :not_deleted, -> {
    where.not({flag: DB_DELETED_FLAG})
  }
  
  scope :find_category, ->(voice_log_id, category_id=0){
    if category_id > 0
      where({ voice_log_id: voice_log_id, call_category_id: category_id})
    else
      where({ voice_log_id: voice_log_id })
    end
  }
  
  def checked?
    return (self.flag != DB_DELETED_FLAG)
  end
  
  def self.update_to_es(voice_log_id)
    cates = find_category(voice_log_id).not_deleted.all
    cates = cates.map { |c| c.call_category_id }
    begin
      vld = ElsClient::VoiceLogDocument.new(voice_log_id)
      if vld.exists?
        vld.update_categories(cates) 
      end
    rescue => e
      Rails.logger.error "Failed for update call category - #{e.message}"
    end
  end
  
  def self.add_call_type(voice_log_id, call_type)
    cate = CallCategory.where(code_name: call_type).first
    unless cate.nil?
      result = where(voice_log_id: voice_log_id, call_category_id: cate.id).first
      if result.nil?
        result = new(voice_log_id: voice_log_id, call_category_id: cate.id)
        result.save
        update_to_es(voice_log_id)
      end
    end
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
  end

  def undo_delete
    unless checked?
      self.flag = ""
      return true
    end
    return false
  end
  
end
