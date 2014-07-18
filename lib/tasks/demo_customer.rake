NUMBER_OF_CUSTOMERS = 100

namespace :demo do

   desc 'Create log test data'
   task :customer => :setup do
      Rake::Task['demo:customer:remove'].invoke
      Rake::Task['demo:customer:create'].invoke
   end

   namespace :customer do
      desc 'Delete all '
      task :remove => :setup do
        remove_customer
      end

      desc 'Create all '
      task :create => :setup do
        create_customer
      end

      desc 'Create all '
      task :create_car => :setup do
        create_cars_no
      end    
   end
end

def create_customer

  customer_names = []
  customer_names_file = File.join(File.dirname(__FILE__),"CUSTOMERS.txt")
  File.open(customer_names_file).each do |line|
    customer_names << "#{line.to_s.strip}".downcase
  end
  
  customer_names.each do |c|
    
    cust = Customer.new(:customer_name => c)
    cust.save
    
    (1 + rand(3)).times do 
        case rand(3)
        when 0
          phone = '08' + sprintf('%08d',rand(1000000))    
        when 1
          phone = '02' + sprintf('%07d',rand(1000000)) 
        else
          phone = '0' + (rand(7) + 1).to_s + sprintf('%07d',rand(1000000)) 
        end
        CustomerNumber.new(:customer_id => cust.id ,:number => phone).save
    end
    
  end
  
end

def create_cars_no
    del_cars_no
    
    chrs = "กขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรลวศษสหฬอฮ".split("")
    
    cs = Customer.all
    cs.each do |c|
        (1 + rand(2)).times do
            ch = "#{chrs[rand(chrs.length)]}#{chrs[rand(chrs.length)]}"
            no = sprintf("%04d",rand(10000)).to_s          
            CarNumber.new({:customer_id => c.id, :car_no => "#{ch}#{no}"}).save!
            ch = nil
            no = nil
        end
    end
  
end

def del_cars_no
  CarNumber.delete_all
end

def remove_customer

  STDERR.puts "--> Removing customer and phone ..."
  
  Customer.delete_all
  CustomerNumber.delete_all

end