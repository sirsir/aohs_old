class UserAtlAttr < ActiveRecord::Base

  belongs_to  :user
  
  scope :find_by_key, ->(c){
    cond = {
      operator_id: c[:operator_id],
      team_id: c[:team_id]
    }
    where(cond)
  }
  
  scope :find_by_oper_id, ->(id){
    where(operator_id: id)  
  }
  
  scope :find_by_user_id, ->(user_id){
    where(user_id: user_id)  
  }
  
  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)
  }
  
  scope :only_deleted, ->{
    where(flag: DB_DELETED_FLAG)
  }
  
  scope :order_by_default, ->{
    order([:created_at, :updated_at, :id])
  }
  
  scope :order_by_latest, ->{
    order({ updated_at: :desc })
  }
  
  scope :order_by_mapping, ->{
    order("operator_id, dummy_flag, updated_at")  
  }

  scope :section_id, ->{
    section_ids = where('flag <> ?','D').order({ updated_at: :desc }).pluck(:section_id)
    if section_ids.length == 0
      return ''
    else
      return section_ids.first
    end
  }
  
  scope :last_update_ndays_ago, ->(n=0){
    where(["updated_at >= ?", Date.today - n.days])
  }
  
  def self.create_or_update(user_id, data)
    
    # transaction key (data):
    # 1. operator_id
    # 2. team_id
    # 3. performace_group_id
    
    do_remove_old(user_id, data)
    is_changed = true
    rec = nil
    
    recs = where(user_id: user_id).find_by_key(data).not_deleted.all
    recs.each do |orec|
      unless orec.key_changed?(data)
        is_changed = false
        rec = orec
      end
    end
    
    if is_changed
      # create new
      rec = UserAtlAttr.new
    end
    
    unless rec.nil?
      rec.user_id = user_id
      rec.operator_id = data[:operator_id].to_s
      rec.team_id = data[:team_id].to_s
      rec.performance_group_id = data[:performance_group_id].to_s
      rec.section_id = data[:section_id]
      rec.delinquent_no = data[:delinquent].to_s
      rec.extension = data[:extension].to_s
      rec.dummy_flag = data[:dummy]
      rec.grade = data[:grade]
      rec.save
    end

    return rec
  end
  
  def key_changed?(data)
    d = data
    bln = (self.operator_id == d[:operator_id]) and (self.team_id == d[:team_id]) and (self.performance_group_id == d[:performance_group_id]) and (self.section_id == d[:section_id])
    return (not bln)
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG  
  end
  
  def team_name
    t = SystemConst.find_value("atl-teams",self.team_id).first
    return (t.nil? ? nil : t.name)
  end
  
  def performance_group_name
    t = SystemConst.find_value("atl-perfgroups",self.performance_group_id).first
    return (t.nil? ? nil : t.name)
  end
  
  def section_name
    t = SystemConst.find_value("atl-sections",self.section_id).first
    return (t.nil? ? nil : t.name)
  end
  
  private
  
  def self.do_remove_old(user_id, data)
    recs = find_by_oper_id(data[:operator_id]).all
    recs.each do |r|
      next if r.user_id == user_id
      r.do_delete
      r.save
    end
  end
  
end
