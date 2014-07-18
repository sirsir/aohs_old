namespace :demo do

   desc 'Reset keywords ...'
   task :keywords => :setup do

      Rake::Task["demo:keywords:delete"].invoke
      Rake::Task["demo:keywords:create"].invoke
	  
   end

   namespace :keywords do

      desc 'Delete all'
      task :delete => :setup do
        remove_keyword
      end

      desc 'Create all'
      task :create => :setup do
        create_keyword
      end
	  
   end
   
end

def create_keyword

	STDERR.puts "--> Creating keywords ..."

	keywords_file = "KEYWORDS.txt"
	keywords_file = File.join(File.dirname(__FILE__),keywords_file)

	if File.exists?(keywords_file)
		File.open(keywords_file).each do |line|
		  ktype, kname, kgroup = line.strip.split(',',3)

          keyword = Keyword.new(:name => kname,:keyword_type => ktype)
          keyword.save
          keyword = Keyword.find(:first,:conditions => {:name => kname,:keyword_type => ktype})
          unless kgroup.blank?
            kgroups = kgroup.strip.split(",")
            unless kgroups.each do |kg|
              next if kg.blank?
              kg = kg.strip
              tkg = KeywordGroup.find(:first,:conditions => {:name => kg})
              if tkg.nil?
                tkg = KeywordGroup.new(:name => kg)
                tkg.save
              end
              km = KeywordGroupMap.new(:keyword_id => keyword.id, :keyword_group_id => tkg.id)
              km.save
            end
          end
		end
        end
    end
  
end

def remove_keyword
	
	STDERR.puts "--> Removing keywords ..."
	
	Keyword.delete_all()
	KeywordGroup.delete_all()
    KeywordGroupMap.delete_all()
  
end