begin
  require 'amivoice_preprocessor'
rescue LoadError
end

module AppUtils
  class TextPreprocessor
    
    def self.norm_text(text, mode=:default)
      tp = TextPreprocessor.new(text, mode)
      if defined? AmiVoicePreprocessor
        return tp.result
      else
        return nil
      end
    end
    
    def initialize(text, mode=:default)
      @raw_text = formatted(text)
      @output_mode = mode
      @norm_text = nil
    end
    
    def result
      @norm_text = escape_string(@raw_text)
      begin
        normalizer = AmiVoicePreprocessor::Normalizer.new()
        norm_text, semi_norm_text = normalizer.normalize_text(@raw_text + "'", true)
        unless norm_text.empty?
          @norm_text = norm_text
          @semi_norm_text = semi_norm_text
          @org_text = fix_word_segmenters(@raw_text, @semi_norm_text)
        end
      rescue => e
        STDERR.puts "Error to normalize text, #{e.message}"
      end
      STDOUT.puts "AmiVoicePreprocessor - normalized Text from '#{@raw_text}' to '#{@norm_text}' and '#{@semi_norm_text}'"
      
      # fix no norm result
      if @semi_norm_text.length <= 0
        @semi_norm_text = @norm_text
      end
      
      keymatch = []
      keysearch = []
      
      keysearch << add_dbquote(@semi_norm_text)
      keysearch << add_dbquote(@org_text)
      keysearch << @semi_norm_text
      
      keymatch  << remove_space(@raw_text)
      keymatch  << remove_space(@semi_norm_text)
      
      keysearch = keysearch.uniq.join(" ")
      STDOUT.puts "AmiVoicePreprocessor - text search: #{keysearch}"
      STDOUT.puts "AmiVoicePreprocessor - text match: #{keymatch.join(" ")}"
      
      case @output_mode
      when :mysqlfulltext
        return @norm_text, @semi_norm_text
      end
      return keysearch, keymatch
    end
    
    private
    
    def fix_word_segmenters(otext,ntext)
      src_txts = ntext.split(/\s+/)
      src_txts = (src_txts.sort { |a| a.size }).reverse
      src_txts.each { |t|
        otext = otext.gsub(t," #{t} ")
      }
      otext = otext.to_s.gsub(/\s+/," ").strip
      return otext
    end
    
    def remove_space(text)
      return text.to_s.gsub(/\s+/,"")  
    end
    
    def add_dbquote(text)
      return "\"#{text}\""  
    end
    
    def escape_string(text)
      return text.to_s.gsub(/'/,"")  
    end
    
    def formatted(text)
      return text.to_s.chomp.strip  
    end
    
  end
end
