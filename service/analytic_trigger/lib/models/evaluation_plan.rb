class EvaluationPlan < ActiveRecord::Base
  
  # rule data structure
  # rule_type: [<list>]
  serialize :rules, JSON
  serialize :call_settings, JSON

  scope :not_deleted, ->{
    where.not(flag: 'D')  
  }

  scope :only_auto_assessment, ->{
    not_deleted.where(asst_flag: "Y")
  }

  def matched_asst_form?(voice_log)
    is_matched, score = matched_condition_score(voice_log)
    return is_matched
  end
  
  def matched_condition_score(voice_log)
    # to check call details and form condition
    is_matched = []
    matched_score = 0
    
    if not voice_log.nil? and not self.call_settings.blank?
      rules = self.call_settings
      if rules["call_category"].present? and rules["call_category"].length > 0
        cates_ok = []
        rules["call_category"].each do |cates|
          cates = cates.map { |c| c.to_i } 
          voice_log.call_category_ids.each do |cate_id|
            if cates.include?(cate_id)
              cates_ok << true
              break
            end
          end
        end
        # matched if found = matched or empty
        matched_score += cates_ok.length
        is_matched << (cates_ok.length >= rules["call_category"].length)
      end
      if rules["min_duration"].present?
        if voice_log.duration.to_i > rules["min_duration"].to_i
          is_matched << true
          matched_score += 1
        else
          is_matched << false
        end
      end
      if rules["call_diretion"].present?
        if voice_log.call_direction == rules["call_diretion"]
          is_matched << true
          matched_score += 1
        else
          is_matched << false
        end
      end
    end
    # matched if empty? or true
    is_matched = (is_matched.empty? or (not is_matched.include?(false)))
    matched_score = -1 unless is_matched
    return is_matched, matched_score
  end
  
  #def matched_asst_form?(voice_log)
  #  # to check call details and form condition
  #  is_matched = []
  #  if not voice_log.nil? and not self.call_settings.blank?
  #    rules = self.call_settings
  #    if rules["call_category"].present?
  #      cates_ok = []
  #      voice_log.call_category_ids.each do |cate_id|
  #        cate_ok = false
  #        rules["call_category"].each do |cates|
  #          cates = cates.map { |c| c.to_i }
  #          cate_ok = cates.include?(cate_id)
  #          #STDOUT.puts "#{cates.inspect} | #{cate_id}"
  #          break unless cate_ok
  #        end
  #        cates_ok << cate_ok
  #        is_matched << cates_ok.include?(true)
  #      end
  #    end
  #    if rules["min_duration"].present?
  #      if voice_log.duration.to_i > rules["min_duration"].to_i
  #        is_matched << true
  #      else
  #        is_matched << false
  #      end
  #    end
  #    if rules["call_diretion"].present?
  #      if voice_log.call_direction == rules["call_diretion"]
  #        is_matched << true
  #      else
  #        is_matched << false
  #      end
  #    end
  #  end
  #  # matched if empty? or true
  #  return (is_matched.empty? or (not is_matched.include?(false)))
  #end

  # end class
end
