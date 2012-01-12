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
   end
end

def create_customer

  STDERR.puts "--> Creating customer and phone ..."

  phones = VoiceLogTemp.find(:all,
                :select => 'dnis',
                :group => 'dnis',
				:order => 'start_time desc',
                :limit => 5000)

  customer_names = []
  customer_names_file = File.join(File.dirname(__FILE__),"CUSTOMERS.txt")
  File.open(customer_names_file).each do |line|
    customer_names << "#{line.to_s.strip}".downcase
  end
  
  unless phones.blank?
    i = 5
    current_customer = ""
    cust_id = 0
    phones.each do |pc|

      next if pc.dnis.nil?
      
      p_number = pc.dnis

      # add cust

      if i >= 5
        i = 0
        current_customer = customer_names.shift
        if current_customer.nil?
          current_customer = customer_names[rand(customer_names.length)].to_s + rand(1000).to_s
        end
        if not Customers.exists?(:customer_name => current_customer)
          Customers.new(:customer_name => current_customer).save
        end
        cust_id = Customers.find(:first,:conditions => {:customer_name => current_customer}).id
        i = i + rand(2)
      end

      STDERR.puts " get #{current_customer},#{p_number}"
      
      i = i + 1

      # add numbers
      phone_id = nil
      if not CustomerNumbers.exists?(:customer_id => cust_id ,:number => p_number)
        CustomerNumbers.new(:customer_id => cust_id ,:number => p_number).save
        phone_id = CustomerNumbers.find(:first,:conditions => {:customer_id => cust_id ,:number => p_number}).id
      end

      # map cust and number

      vcs = VoiceLogTemp.find(:all,:conditions => "(ani = '#{p_number}' or dnis = '#{p_number}')", :limit => 1000)
      unless vcs.empty?
        vcs.each do |vc|
          x = VoiceLogCustomer.create(:voice_log_id => vc.id, :customer_id => cust_id)
        end
      end

      STDERR.puts " add -"
      
    end
  end

end

def remove_customer

  STDERR.puts "--> Removing customer and phone ..."
  
  Customers.delete_all
  CustomerNumbers.delete_all
  VoiceLogCustomer.delete_all 
end