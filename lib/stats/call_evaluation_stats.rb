require 'json'

module StatsData
  
  PREV_CHECK_DAYS = 0
  
  class QuestionCounter < StatsBase
    def self.run(options={})
      qc = new(options)
      qc.run
    end
    
    def run
      date_list = get_datelist
      date_list.each do |date| 
        update(date)
      end
    end
    
    private
    
    def get_datelist
      sql = []
      sql << "SELECT DISTINCT c.call_date"
      sql << "FROM evaluation_logs l JOIN evaluation_calls c"
      sql << "ON l.id = c.evaluation_log_id"
      # sql << "WHERE l.flag <> 'D'"
      sql << "AND (c.call_date BETWEEN '#{@options[:start_date] - PREV_CHECK_DAYS}' AND '#{@options[:end_date]}'"
      sql << "OR l.updated_at BETWEEN '#{@options[:start_date] - PREV_CHECK_DAYS} 00:00:00' AND '#{@options[:end_date]} 23:59:59')"
      dates = select_all(jn_sql(sql))
      dates = dates.map { |d| d["call_date"] }
      dates = dates.concat((@options[:start_date]..@options[:end_date]).to_a)
      return dates.uniq.sort
    end
    
    def update(at_date)
      # select and count
      data = select_data(at_date)
      counter = {}
      unless data.empty?
        data.each do |da|
          agent_id = da["agent_id"].to_s
          group_id = da["group_id"].to_s
          form_id = da["evaluation_plan_id"].to_s
          question_id = da["evaluation_question_id"].to_s
          counter[group_id] = {} if counter[group_id].nil?
          counter[group_id][agent_id] = {} if counter[group_id][agent_id].nil?
          counter[group_id][agent_id][form_id] = {} if counter[group_id][agent_id][form_id].nil?
          counter[group_id][agent_id][form_id][question_id] = {} if counter[group_id][agent_id][form_id][question_id].nil?
          choices = JSON.parse(da["answer"])
          choices.each do |choice|
            next if choice["deduction"] == "uncheck"
            next if choice["title"].nil? or choice["title"].blank?
            counter[group_id][agent_id][form_id][question_id][choice["title"]] = 0 if counter[group_id][agent_id][form_id][question_id][choice["title"]].nil?
            counter[group_id][agent_id][form_id][question_id][choice["title"]] += 1
          end
        end
      end
      logger.info "Found #{counter.length} records need to update."
      
      # remove existing data
      remove_existing_record(at_date)
      logger.info "Removed existing records"
      
      # fetech and update
      counter.each do |group_id, agents|
        agents.each do |agent_id, forms|
          forms.each do |form_id, questions|
            questions.each do |question_id, choices|
              choices.each do |title, cnt|
                next if cnt <= 0
                da = {
                  call_date: db_datetime(at_date),
                  agent_id: agent_id,
                  group_id: group_id,
                  evaluation_plan_id: form_id,
                  evaluation_question_id: question_id,
                  choice_title: title,
                  record_count: cnt
                }
                insert_record(da)
              end
            end
          end
        end        
      end

      logger.info "Records was updated. "
      
      # end update
    end
    
    def remove_existing_record(at_date)
      sql = []
      sql << "DELETE evaluation_question_stats"
      sql << "FROM evaluation_question_stats"
      sql << "WHERE call_date = '#{db_datetime(at_date)}'"
      execute_sql(jn_sql(sql))
    end
    
    def insert_record(record)
      begin
        fields = []
        values = []
        record.each do |key,value|
          fields << key
          values << value
        end
        sql = []
        sql << "INSERT INTO evaluation_question_stats(#{fields.map{ |c| "`#{c}`"}.join(",")})"
        sql << "VALUES(#{(values.map { |v| "'#{v}'"}).join(",")})"
        execute_sql(jn_sql(sql))
      rescue => e
        Rails.logger.info e.message
      end
    end
    
    def select_data(at_date)
      sql = []
      
      select = [
        "l.id",
        "l.user_id AS agent_id",
        "l.group_id",
        "l.evaluation_plan_id",
        "s.evaluation_question_id",
        "s.answer"
      ]
      
      where = [
        "l.flag <> 'D'",
        "p.flag <> 'D'",
        "s.evaluation_question_id IN (#{get_question_ids.join(",")},0)",
        "EXISTS (SELECT 1 FROM evaluation_calls c WHERE c.call_date BETWEEN '#{at_date}' AND '#{at_date}' AND l.id = c.evaluation_log_id)"
      ]
      
      sql << "SELECT #{jn_select(select)}"
      sql << "FROM evaluation_logs l"
      sql << "JOIN evaluation_plans p ON l.evaluation_plan_id = p.id"
      sql << "JOIN evaluation_score_logs s ON s.evaluation_log_id = l.id"
      sql << "WHERE #{jn_where(where)}"
      return select_all(jn_sql(sql))
    end
    
    def get_question_ids
      quests = EvaluationQuestion.select(:id, :code_name).all
      logger.info "update only questions: #{quests.to_json}"
      return quests.map { |q| q.id }
    end
    
  end
end