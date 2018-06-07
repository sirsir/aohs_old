class VoiceLog < ActiveRecord::Base
  
  scope :minimum_select, ->{
    select(:id,:call_id,:start_time,:call_direction,:duration,:ani,:dnis,:extension,:agent_id)  
  }

  def update_call_categories(names)
    ocates = []
    names = names.compact.uniq.sort
    names.each do |cate_name|
      cate = CallCategory.where(code_name: cate_name).first
      unless cate.nil?
        result = CallClassification.where(voice_log_id: self.id, call_category_id: cate.id).first
        if result.nil?
          result = CallClassification.create(voice_log_id: self.id, call_category_id: cate.id)
          ocates << result
        end
      end
    end
    return ocates
  end
  
  
  def private_call?
    sql =  " SELECT COUNT(0) AS log_count FROM call_categories c JOIN call_classifications cl"  
    sql << " ON c.id = cl.call_category_id AND cl.flag <> 'D'"
    sql << " WHERE c.code_name = 'private' AND cl.voice_log_id = '#{self.id}'"
    result = AnalyticTrigger::SqlClient.select_all(sql).first
    return (result["log_count"].to_i > 0)
  end
  
  def call_category_ids
    cates = CallClassification.where(voice_log_id: self.id)
    cates = cates.where.not(flag: "D")
    cates.select(:call_category_id).all.map { |cc| cc.call_category_id }
  end

  def call_category_codes
    return CallCategory.where(id: call_category_ids).all.map { |c| c.code_name.downcase }
  end
  
  def get_tm_or_cs
    # for cigna only
    call_type = nil
    call_types = call_category_codes
    if call_types.include?("tm")
      return "tm"
    elsif call_types.include?("cs")
      return "cs"
    end
    return nil
  end
  
  private
  
end