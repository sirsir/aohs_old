module AnalyticUtils
  class AssessmentRuleBase
    
    def self.rules
      get_rule_base
    end
    
    def self.rules_data      
      return generate_rule_base
    end
  
    private
  
    def self.generate_rule_base
      output_rules = []
      questions = EvaluationQuestion.not_deleted.all
      unless questions.empty?
        questions.each do |question|
          r = {
            question_id: question.id,
            question: question.title,
            last_updated: question.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
            type: nil,
            choices: []
          }
          found_rule = false
          answers = question.evaluation_answers.not_deleted.all
          unless answers.empty?
            stmp_default = false
            answers.each do |answer|
              r[:type] = answer.answer_type
              answer.answer_list.each do |ans|
                a = {
                  return_result: ans["title"],
                  rules: parse_rule(ans["rules"]),
                  last_updated: answer.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
                  default: false
                }
                a[:rules] = nil if a[:rules].blank?
                if a[:rules].nil? and not stmp_default and answer.answer_type == "radio"
                  a[:default] = true
                  stmp_default = true
                end
                found_rule = true unless a[:rules].nil?
                r[:choices] << a
              end
            end 
          end
          if found_rule
            output_rules << r
          end
        end
      end
      return output_rules
    end
    
    def self.parse_rule(rule)
      out_r = nil
      unless rule.nil?
        if rule.is_a?(Hash) and rule.has_key?("condition")
          out_r = {
            condition: rule["condition"],
            rules: parse_rule(rule["rules"])
          }
          return nil if out_r[:rules].nil?
        else
          if rule.is_a?(Array)
            out_r = (rule.map { |r| parse_rule(r) }).compact
            out_r = nil if out_r.blank?
          else
            out_r = mapped_rule(rule)
          end
        end
      end
      return out_r
    end
    
    def self.mapped_rule(rule)
      case rule["id"]
      when "template_matching"
        r = AutoAssessmentRule.only_template_matching.where(id: rule["value"]).first
        unless r.nil?
          return {
            operator: rule["operator"],
            engine: rule["id"],
            name: r.name,
            options: r.rule_options2
          }
        end
      when "talking_speed_detection"
        return {
          engine: 'talking_speed_detection',
          operator: rule["operator"],
          unit: "spm",
          value: rule["value"].to_i
        }
      when "holding_time"
        return {
          engine: 'slience_detection',
          operator: rule["operator"],
          unit: "second",
          value: rule["value"].to_i
        }
      end
      return nil
    end
    
    def self.get_rule_base
      return load_from_file
    end
    
    def self.config_file_path
      dir_base = File.dirname(File.expand_path(__FILE__)).gsub("/analytics","")
      config_file = File.join(dir_base,"data","analytic_rules.json")
      return config_file
    end
    
    def self.load_from_file
      # load initial data
      data = JSON.parse(File.read(config_file_path))
      
      # load additional data
      # template matching : list
      data["template_matching"]["options"]["values"] = get_list_of_template_matching
      
      return data
    end
    
    def self.get_list_of_template_matching
      ds = {}
      list = AutoAssessmentRule.only_template_matching.not_deleted.order_by_default.all
      list.each do |t|
        ds[t.id.to_s] = t.name
      end
      return ds
    end
    
  end
end