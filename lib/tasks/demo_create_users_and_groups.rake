namespace :demo do

   desc 'Create user and group test data'
   task :users_and_groups => :setup do
      Rake::Task["demo:users_and_groups:delete"].invoke
      Rake::Task["demo:users_and_groups:create_category"].invoke
      Rake::Task["demo:users_and_groups:create_display_tree"].invoke
      Rake::Task["demo:users_and_groups:create_users_and_groups"].invoke
   end

   namespace :users_and_groups do

      desc 'Delete all'
      task :delete => :setup do
         targets = [Group, GroupCategory, GroupCategorization, GroupCategoryDisplayTree, GroupCategoryType]
         targets.each do |m|
            m.delete_all()
         end
         User.delete_all("login <> 'AohsAdmin'")
      end

      desc 'Create category'
      task :create_category => :setup do
         create_category
      end

      desc 'Create category display tree'
      task :create_display_tree => :setup do
         create_category_display_tree
      end

      desc 'Create user and group'
      task :create_users_and_groups => :setup do
         create_groups_and_users
      end

   end
end

def create_category

    STDERR.puts "--> Creating category ... "

    categories_type = [
      {:name => "Department",:member => ["Dept A1","Dept B1","Dept C1","Dept D1","Dept A2","Dept B2","Dept C2"]},
      {:name => "Branch",:member => ["Branch A","Branch B","Branch C","Branch D"]},
      {:name => "Site",:member => ["Bangkok","ChiangMai","HadYai"]},
      {:name => "Country",:member => ["Thailand"]}
    ]

#    categories_type = [
#      {:name => "Department",:member => ["Non-Motor","Motor","Finance"]},
#      {:name => "Site",:member => ["Bangkok","Khonkaen"]}
#    ]
    
    categories = {}
    categories_type.each do |x|

      GroupCategoryType.new(:name => x[:name]).save
      gct_id = GroupCategoryType.find(:first,:conditions => {:name => x[:name]}).id
      
      x[:member].each do |y|
        gc = GroupCategory.new(:group_category_type_id => gct_id, :value => y).save!
        gc_id = gc.id
        if categories["#{x[:name]}"].nil?
          categories["#{x[:name]}"] = [gc_id]
        else
          categories["#{x[:name]}"] << gc_id
        end
      end

    end

end

def create_category_display_tree

    STDERR.puts "--> Creating category display tree ... "

    gcts = GroupCategoryType.find(:all,:order => 'id desc')

    gcts_id = []
    gcts.each do |gct|
      gcts_id << gct
    end
    #gcts_id.reverse
    parent_id = nil
    gcts_id.each do |gct|
      GroupCategoryDisplayTree.new({:group_category_type => gct,:parent_id => parent_id }).save!
      gcdt_id = GroupCategoryDisplayTree.find(:first,:conditions => {:group_category_type => gct}).id
      parent_id = gcdt_id
    end

end

def create_groups_and_users

    $NUMBER_OF_GROUP = 12
    $NUMBER_OF_USER_PER_GROUP = 6
	
    STDERR.puts "--> Creating users and groups ..."
    STDERR.puts "   -> Groups [#{$NUMBER_OF_GROUP}]"
    STDERR.puts "   -> Users  [#{$NUMBER_OF_GROUP * $NUMBER_OF_USER_PER_GROUP}]"
    
	agent_cti_id = 1000
  
    id_card = 1000
  
	gcts = GroupCategoryType.find(:all)

    gcts_id = {}
    gcts.each do |gct|
      gc = GroupCategory.find(:all,:conditions => { :group_category_type_id => gct.id })
      gcts_id["#{gct.name}"] = []
      gc.each do |y|
        gcts_id["#{gct.name}"] << y.id
      end
    end
    
    first_name = []
    first_name_file = File.join(File.dirname(__FILE__),"FIRST_NAME.txt")
    File.open(first_name_file).each do |line|
      first_name << "#{line.to_s.strip}".downcase
    end

    last_name = []
    last_name_file = File.join(File.dirname(__FILE__),"LAST_NAME.txt")
    File.open(last_name_file).each do |line|
      last_name << "#{line.to_s.strip}".downcase
    end

    roles = Role.where("name != 'Agent'")
    agent_run_number = 0
    
    fi = 0
    li = 0
    
    ActiveRecord::Base.transaction do

      $NUMBER_OF_GROUP.times do |i|

        group_name = sprintf('Team %03d', i)

        STDERR.puts "   -> Updating groups ... #{group_name}"

        Group.new({:name => group_name,:description => "AohsWeb Team example."}).save
        team_id = Group.find(:first,:conditions => {:name => group_name}).id
        
        $NUMBER_OF_USER_PER_GROUP.times do |j|
            agent_run_number = agent_run_number + 1
            id_card += 1 
            fname = ("#{first_name[fi]}").gsub(' ','')
            lname = last_name[li]
            login = "#{fname}#{lname.first}"
            agent = Agent.new({:display_name => "#{fname} #{lname}", :role_id => 2, :login => login, :group_id => team_id, :cti_agent_id => agent_cti_id, :id_card => sprintf("%013d",id_card) })
            agent.reset_password Aohs::DEFAULT_PASSWORD_NEW
            agent.save!
            agent.state = "active"
            agent.save!
			      agent_cti_id += 1
            
            li += 1
            fi += 1
            fi = 0 if fi == first_name.length
            li = 0 if li == last_name.length
        end
		
		nno = sprintf('%02d', i)
		nfname = first_name[rand(first_name.length)] + nno
		nlname = last_name[rand(last_name.length)]
		nlogin = "#{nfname}#{nlname.first}"
		id_card += 1
        m = Manager.new({:display_name => "#{nfname} #{nlname}", :login => nlogin, :cti_agent_id => agent_cti_id, :email => "#{nfname}@mailserver.com",:id_card => sprintf("%013d",id_card) })
        m.role = roles[rand(roles.length)]
        m.reset_password Aohs::DEFAULT_PASSWORD_NEW
        m.save!
        m.state = "active"
        m.save!
		agent_cti_id += 1
		
        Group.update(team_id,{:name => nfname, :leader_id => m.id })

        gcts.each do |z|
          cates = gcts_id["#{z[:name]}"]
          gcs_id = cates[rand(cates.length)]
          GroupCategorization.new({:group_id => team_id,:group_category_id => gcs_id}).save
        end
		
      end

	  STDERR.puts "   -> Updating Manager User ..."
	  
	  Role.where("name != 'Agent'").each do |r|
		i = 1
		5.times do 
      id_card += 1  
			nno = sprintf('%02d', i)
			nfname = first_name.shift + nno
			nlname = last_name[rand(last_name.length)]
			nlogin = "#{nfname}#{nlname.first}"
			
			m = Manager.new({:display_name => "#{nfname} #{nlname}",:role_id => r.id , :login => nlogin, :cti_agent_id => agent_cti_id, :email => "#{nlogin}@mailserver.com", :id_card => sprintf("%013d",id_card)})
			m.reset_password Aohs::DEFAULT_PASSWORD_NEW
			m.save!
			m.state = "active"
			m.save!
			agent_cti_id += 1	
			i += 1
      
		end
		
	  end
	
	  STDERR.puts "   -> Updating Extension ..."
	  
	  ext = 1000
	  User.find(:all).each do |u|
		  new_ext = Extension.create({:number => ext})
      ext += 1
	  end
	  
    end

end

def gfchar(s)
	return s[0,1]
end