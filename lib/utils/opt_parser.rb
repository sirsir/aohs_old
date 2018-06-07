require 'hashie'

module AppUtils
  
  #
  # helper class for options or parameters
  #
  # main class
  #
  
  class OptParser
    
    def self.parse(options={})
      return new(options)
    end
    
    def initialize(opts)
      @options = Hashie::Mash.new(mapopts(opts.to_h))  
    end

    def options
      return @options
    end
    
    def is?(name)
      return (@options[name] == true)
    end
    
    def read(question)
      begin
        STDOUT.puts "#{question}"
        return STDIN.gets.chomp.strip
      rescue
      end
      return nil
    end
    
    def confirm?(question, name=nil)
      if read(question + " <yes>") == "yes"
        return true
      end
      return false
    end
    
    def force_delete?
      return (@options[:force_delete] == true)  
    end

    def show_options
      STDOUT.puts "Input Options:"
      STDOUT.puts @options.inspect  
    end
    
    private
    
  end

  #
  # thor options
  #
  
  class ThorOptionParser < OptParser
    
    private
    
    def mapopts(opts)
      if opts.has_key?("role_id") and not opts["role_id"].blank?
        opts["role_id"] = opts["role_id"].split(",").map { |x| x.strip }
      end
      if opts.has_key?("user_id") and not opts["user_id"].blank?
        opts["user_id"] = opts["user_id"].split(",").map { |x| x.strip }
      end
      return opts
    end
    
  end
  
  # end module
end
