class CarNumber < ActiveRecord::Base
  
  belongs_to :customer
  
  #validates_length_of         :car_no, :within => 14..15
  
  scope :without_delete, where("(car_numbers.flag not like 'd' or car_numbers.flag is null)")
  
  def self.valid_car_pattern(a=[])
    
    r = "[0-9,A-Z,a-z,กขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรฤลฦวศษสหฬอฮ]"
    
    result = true
    unless a.empty?
      a.each do |b|
        begin
          if b.strip.length <= 0
            result = false
            break
          end
          matched = true #(not (b.strip =~ /#{r}{0,4}\-#{r}{0,5} #{r}{0,4}/).nil?)
          if not matched
            result = false
            break
          end
          result = true
        rescue => e
          STDERR.puts "CheckCar #{e.message}"
        end
      end
    end
    return result
    
  end
  
end
