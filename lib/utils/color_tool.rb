module AppUtils
  
  # class for manipulate about color code
  # chroma ref: https://github.com/jfairbank/chroma
  
  class ColorTool
    
    BRIGHTEN_VALUE = 100
    DARKEN_VALUE = 100
    
    def self.oposite_color(hex_code)
      cob = hex_code.paint
      if cob.dark?
        return cob.brighten(BRIGHTEN_VALUE)
      end
      return cob.darken(DARKEN_VALUE)
    end
    
    private
    
    # end class
  end
  
end