class MakeResultKeyword
  
  def self.make_log(d)
  
    must_words = Keyword.only_mustword.select([:id,:name,:keyword_type]).to_a
    ng_words   = Keyword.only_ngword.select([:id,:name,:keyword_type]).to_a
    
    voice_logs = VoiceLog.select([:id]).at_date(d).where(["duration >= 60 AND duration <= 240"]).all
    voice_logs.each do |v|
      
      rs_count = ResultKeyword.of_voicelog(v.id).count(0)
      if rs_count <= 0
        
        next if rand(10) == 5
        
        keywords = []
        keywords << must_words[rand(must_words.length-1)]
        keywords << ng_words[rand(ng_words.length-1)] if rand(10) > 8
        
        stime = 1000
        keywords.each do |k|
          rsk = {voice_log_id: v.id, start_msec: stime, end_msec: stime + 1000, keyword_id: k.id }
          rsk = ResultKeyword.new(rsk)
          rsk.save
          stime = stime + 5000 + rand(5000)
        end
        
        STDOUT.puts "create keywords #{v.id} -> #{keywords.inspect}"
        
      end
      
    end
    
  end
  
end