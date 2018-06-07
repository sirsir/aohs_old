class UserExtensionMap < ActiveRecord::Base
  
  scope :find_by_extension, ->(n){
    where(extension: n)  
  }
  
  scope :find_by_did, ->(n){
    where(did: n)  
  }
  
  scope :find_by_agent_id, ->(n){
    where(agent_id: n)  
  }
  
  def self.create_or_update(data, replace_flag=true)
    # type of number:
    # 1. extension
    # 2. did
    
    need_update = true
    
    unless data[:extension].nil?
      logs = find_by_extension(data[:extension]).all
      logs.each do |log|
        log.set_agent(data[:agent_id])
        log.did = data[:did]
        log.save
        need_update = false
      end
    end
    
    unless data[:did].nil?
      logs = find_by_did(data[:did]).all
      logs.each do |log|
        log.set_agent(data[:agent_id])
        log.save
        need_update = false
      end
    end
    
    if need_update
      uem = UserExtensionMap.new(data)
      uem.save!
    end
  end
  
  def self.remove_mapping(data)
    
    unless data[:extension].nil?
      logs = find_by_extension(data[:extension]).all
      logs.each do |log|
        log.delete
      end
    end
    
    unless data[:did].nil?
      logs = find_by_did(data[:did]).all
      logs.each do |log|
        log.delete
      end
    end
        
  end
  
  def remove_agent
    self.agent_id = 0
  end
  
  def set_agent(a_id)
    self.agent_id = a_id
  end
  
end
