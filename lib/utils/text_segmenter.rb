class TextSegmenter
  
  def self.initial_word_list
    
    if defined? $WORDS_BEFORE and defined? $WORDS_AFTER
      return false
    end
    
    words_file = File.join(Rails.root,"lib/data/segment_words.list")
    word_option = nil
    words_before = []
    words_after = []
    words_both = []
    
    # read words
    
    File.open(words_file).each_line do |line|
      line = line.chomp.strip
      next if line.length <= 1
      
      case line
      when "_BREAK_BEFORE"
        word_option = :before
      when "_BREAK_AFTER"
        word_option = :after
      when "_BREAK_ALL"
        word_option = :both
      else
        case word_option
        when :before
          words_before << line
        when :after
          words_after << line
        when :both
          words_both << line
        end
      end
    end
    
    # make regexp object
    words_before = words_before.map { |w| "(#{w})" }
    $WORDS_BEFORE = Regexp.new(words_before.join("|"))
    words_after = words_after.map { |w| "(#{w})" }
    $WORDS_AFTER = Regexp.new(words_after.join("|"))
    words_both = words_both.map { |w| "(#{w})" }
    $WORDS_BOTH = Regexp.new(words_both.join("|"))
    
    STDOUT.puts "Init Regexp for sentense segmenter (before) #{words_before}"
    STDOUT.puts "Init Regexp for sentense segmenter (after) #{words_after}"
    STDOUT.puts "Init Regexp for sentense segmenter (both) #{words_both}"
    
  end
  
  def self.add_sentense_segmenter(txt)
    initial_word_list

    new_txt = [""]
    txt.split(/ /).each do |s|
      next if s.length <= 0
      if s.length <= 1 or english_word?(s)
        new_txt.concat([" #{s} "])
      else
        s = s.gsub($WORDS_BEFORE) { |w| " #{w}" }
        s = s.gsub($WORDS_AFTER) { |w| "#{w} " }
        s = s.gsub($WORDS_BOTH) { |w| " #{w} " }
        new_txt[new_txt.length - 1] << s
      end
    end
    
    new_txt = new_txt.join.gsub(/ +/," ").strip
    return new_txt
  end

  private
  
  def self.english_word?(txt)
    return (not /[a-zA-Z0-9 ]+/.match(txt.gsub(/(\<\/?\w+\/?\>)/,"")).nil?)
  end
  
end