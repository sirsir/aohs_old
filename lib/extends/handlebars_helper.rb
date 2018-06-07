module HandlebarsHelper
  
  module Helper
    
    def hb(expr,opts={},&block)
      
      hb_expression(['{{','}}'],expr,opts,&block)
    
    end
  
    private
    
    def hb_expression(demarcation,expr,opts,&block)
      
      if block.respond_to? :call
        content = capture(&block)
        output = "#{demarcation.first}##{make(expr, opts)}#{demarcation.last}#{content.strip}#{demarcation.first}/#{expr.split(' ').first}#{demarcation.last}"
      else
        output = "#{demarcation.first}#{make(expr, opts)}#{demarcation.last}"
      end
      
      output.html_safe
      
    end

    def make(expr, opts)
      
      if opts.any?
        expr << " " << options.map {|key, value| "#{key}=\"#{value}\"" }.join(' ')
      else
        expr
      end
      
    end

  end

end