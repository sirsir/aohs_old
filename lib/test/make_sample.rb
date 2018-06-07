class MakeSample
  
  def self.make_groups(n)
    log "Creating groups"
    n.times do 
      group = Fabricate.build(:group)
      begin
        group.save!
      rescue => e
        STDERR.puts e.message
      end
    end
    Group.repair_and_update_sequence_no
  end
  
  def self.make_users(n)
    log "Creating users"
    n.times do
      begin
        user = Fabricate.build(:user)
        if user.do_active(true) and user.save!
          gm = Fabricate.build(:group_member, user_id: user.id)
          gm.save!
        end
      rescue => e
        STDOUT.puts e.message
      end
      Fabrication.clear_definitions
    end
  end

  def self.make_computer_logs(n)
    log "Creating computer_logs"
    n.times do 
      compl = Fabricate.build(:computer_log)
      compl.save!
      Fabrication.clear_definitions
    end
  end

  def self.make_app_logs(d)
    log "Creating app_logs"
    MakeAppLog.make_logs
  end
  
  def self.make_phone_extensions
    log "Creating extensions"
    n = 1000
    n.times do
      ext = Fabricate.build(:extension)
      ext.save!
    end
  end
  
  def self.make_voice_logs(d)
    log "Creating voice logs"
    begin 
      d = Date.parse(d)
    rescue
      STDOUT.puts "No input date or wrong format, will use today"
      d = Date.today  
    end
    MakeVoiceLog.make_log(d)
  end
  
  def self.log(msg)
    STDOUT.puts "#{msg}"
  end
  
end