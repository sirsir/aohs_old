# extended method for class Hahs

class Hash
  
  # remove element of hash which value is nil or empty
  def remove_blank!
    
    self.delete_if do |key, val|
      
      if block_given?
        yield(key,val)
      else
        # Prepeare the tests
        test1 = val.nil?
        test2 = val.empty? if val.respond_to?('empty?') 
        test3 = val.strip.empty? if val.is_a?(String) && val.respond_to?('empty?')

        # Were any of the tests true
        test1 || test2 || test3
      end
      
    end

    self.each do |key, val|
      
      if self[key].is_a?(Hash) && self[key].respond_to?('remove_blank!')
        if block_given?
          self[key] = self[key].remove_blank!(&Proc.new)
        else
          self[key] = self[key].remove_blank!
        end
      end
      
    end

    return self
  
  end
  
end