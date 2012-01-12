# == Schema Information
# Schema version: 20100402074157
#
# Table name: keywords
#
#  id           :integer(11)     not null, primary key
#  name         :string(255)
#  keyword_type :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  deleted_at   :datetime
#  deleted      :boolean(1)
#  created_by   :integer(10)
#  updated_by   :integer(10)
#

class Keyword < ActiveRecord::Base

   has_many :keyword_groups ,:through => :keyword_group_maps
   has_many :keyword_group_maps
  
   validates_presence_of     :name
   validates_uniqueness_of   :name, :case_sensitive => false
   validates_presence_of     :keyword_type
   validates_length_of       :name, :minimum => 3
   
   after_update :after_update_keyword
   
   @@display_keyword_types = {
      "a"=>"Action",
      "m"=>"Must",
      "n"=>"NG"
   }

   def display_keyword_type
      @@display_keyword_types[keyword_type]
   end

   def self.display_keyword_type_name(sym)
      @@display_keyword_types[sym]
   end

   def after_update_keyword
     
      begin
            
        # when type change or deleted
        # recheck all keywords statistics table daily, weekly and monthly
        # 
        if (self.keyword_type != self.keyword_type_was) or self.deleted
          js = JobScheduler.new({:name => "statistics.repair.all", :state => "pedding", :parameters => "keyword=all;agent=none" })
          js.save!

          js = JobScheduler.new({:name => "voice_logs.counter.all", :state => "pedding", :parameters => "keyword=#{self.id};agent=all" })
          js.save!
        end
        
        if self.deleted
          DailyStatistics.delete_all({:keyword_id => self.id}) if DailyStatistics.exists?({:keyword_id => self.id})
          WeeklyStatistics.delete_all({:keyword_id => self.id}) if WeeklyStatistics.exists?({:keyword_id => self.id})
          MonthlyStatistics.delete_all({:keyword_id => self.id}) if MonthlyStatistics.exists?({:keyword_id => self.id})          
        end
        
      rescue => e
        STDERR.puts e.message
      end
    
   end
  
end

