module StatsData
  
  class KeywordCounter < StatsBase
    
    def self.run(options)
      rpcd = new(options)
      rpcd.run
    end
    
    def run
      find_ng_words
      (@options[:start_date]..@options[:end_date]).to_a.each do |dt|
        find_voice_logs(dt)
        find_keywords_count(dt)
        update_keyword_count
      end
    end
    
    private
    
    def find_ng_words
      keywords = Keyword.only_ngword.not_deleted.all
      @keywords_id = keywords.map { |k| k.id }
    end
    
    def find_voice_logs(date)
      @voice_logs = VoiceLog.select(:id).at_date(date).where("duration > 1").all.to_a
    end
    
    def find_keywords_count(date)
      @result = []
      v_index = VoiceLogsIndex::VoiceLog
      v_index = v_index.filter(range: {start_time: { gte: date.strftime("%Y-%m-%d 00:00:00"), lte: date.strftime("%Y-%m-%d 23:59:59") }})
      v_index = v_index.filter{ keyword_results != nil }
      aggs = {
        voice_log_id: {
          terms: {
            field: 'id',
            size: 50 },
          aggs: {
            word_count: {
              terms: {
                field: 'keyword_results.keyword_id',
                size: 50 }
            }
          }
        }
      }
      while not @voice_logs.empty?
        logs = @voice_logs.shift(10)
        unless logs.empty?
          vids = logs.map { |v| v.id }
          vidx = v_index.filter{ id(:or) == vids }
          vidx = vidx.aggregations(aggs)
          vidx = vidx.aggregations(aggs)
          vidx.aggs['voice_log_id']['buckets'].each do |v|
            vo_id = v['key']
            kcnt = 0
            v['word_count']['buckets'].each do |k|
              if @keywords_id.include?(k['key'].to_i)
                kcnt += k['doc_count'].to_i
              end
            end
            next if kcnt <= 0
            @result << {
              voice_log_id: vo_id,
              ng_count: kcnt
            }
          end
        end
      end
    end
    
    def update_keyword_count
      @result.each do |v|
        vc = VoiceLogCounter.where(voice_log_id: v[:voice_log_id]).ngword.first
        if vc.nil?
          vc = VoiceLogCounter.new_ngword_count({ voice_log_id: v[:voice_log_id] })
        end
        vc.valu = v[:ng_count]
        vc.save
      end
    end
    
    # end class
  end
  
  # end module
end