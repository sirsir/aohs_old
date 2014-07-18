# == Schema Information
# Schema version: 20100402074157
#
# Table name: voice_logs
#
#  id             :integer(20)     not null, primary key
#  system_id      :integer(10)
#  device_id      :integer(10)
#  channel_id     :integer(10)
#  ani            :string(30)
#  dnis           :string(30)
#  extension      :string(30)
#  duration       :integer(10)
#  hangup_cause   :integer(10)
#  call_reference :integer(10)
#  agent_id       :integer(10)
#  voice_file_url :string(300)
#  call_direction :string(1)       default("u")
#  start_time     :datetime
#  digest         :string(255)
#  call_id        :string(255)
#  site_id        :integer(10)
#

class VoiceLog < ActiveRecord::Base

  acts_as_taggable_on :tags

  belongs_to  :user, :foreign_key => "agent_id",:conditions => ["flag = ?",false]
  has_one     :voice_log_counter, :foreign_key => "voice_log_id"

  has_one     :voice_log_customer
  has_one     :customer ,:through => :voice_log_customer
  has_many    :voice_log_cars
  has_many    :result_keywords,:conditions => 'edit_status is null',:order => "start_msec"
  has_many    :edit_keywords,:conditions => "edit_status != 'd'",:order => "start_msec"
  has_many    :call_informations , :foreign_key => "voice_log_id",:order => "start_msec"
  has_many    :bookmarks, :class_name => "CallBookmark",:order => "start_msec"

  has_one	    :voice_log_transfer
  has_many	  :transfer_logs, :class_name => "VoiceLogTemp", :foreign_key => "ori_id"
    
  def disposition
      @@disposition = self.voice_file_url
  end

  def start_time_full
    unless self.start_time.nil?
      if self.start_time.is_a?(String)
        @@start_time_full = Time.parse(self.start_time)
      else
        @@start_time_full = self.start_time
      end
    else
        @@start_time_full = nil
    end
  end

  def call_response_time
	xanswer_time = nil
	if self.answer_time.is_a?(String)
		xanswer_time = Time.parse(self.answer_time) rescue nil 
	else
		xanswer_time = self.answer_time
	end
	@@call_response_time = xanswer_time
  end
   
  def start_position_sec
    unless self.call_response_time.nil?
      cr = self.call_response_time.to_time
      st = Time.parse(self.start_time.strftime("%Y-%m-%d %H:%M:%S")).to_time
      return ((cr - st).to_i)
    else
      return 0
    end
  end  

  def tags_exist?
    tag = Taggings.select("id").where(:taggable_id => self.id).first
    return (not tag.nil?)
  end
  
  def extension_number
      if Aohs::EXT_USE_LAST_FOUR_DIGITS
        a = self.extension.to_s
        return a[-4..-1].to_s 
      else
        return self.extension
      end
  end
    
  def call_direction_name
    case self.call_direction
    when 'i'
      call_direction_name = "In"
    when 'o'
      call_direction_name = "Out"
    else
      call_direction_name = "Other"
    end
  end
  
  scope :agents, lambda{ |agent_ids|
    if agent_ids.class == String
      { :conditions => ["agent_id = :agent_id", {:agent_id=>agent_ids}] }
    else
      { :conditions => ["agent_id in (:agent_ids)", {:agent_ids=>agent_ids}] }
    end
  }
  scope :date, lambda { |start_date|
    { :conditions => ["start_date = :start_date", {:start_date=>start_date}] }
  }

  Annotation = Struct.new(:Annotation, :type, :start_sec, :end_sec, :description,:keyword_type)
  
  def annotations
    # [TODO] marge and sort by start_msec
    ret = []
    self.result_keywords.each do |rk|
     # ret << Annotation.new("", "keyword", rk.start_sec, rk.end_sec, "#{rk.keyword.name}")
       ret << Annotation.new("#{rk.id}", "keyword", rk.start_sec, rk.end_sec, "#{rk.keyword.name}","#{rk.keyword.keyword_type}")
    end
    self.edit_keywords.each do |rk|
      ret << Annotation.new("#{rk.id}", "keyword", rk.start_sec, rk.end_sec, "#{rk.keyword.name}","#{rk.keyword.keyword_type}")
    end
    self.call_informations.each do |rk|
      ret << Annotation.new("#{rk.id}", "call_information", rk.start_sec, rk.end_sec, "#{rk.event} #{rk.agent_id.blank? || rk.agent_id == 0 ? "&nbsp;" : ( (not User.find(:first,:conditions => {:id => rk.agent_id}).nil?) ? User.find(rk.agent_id).display_name : "-")} ","call_info")
    end
    self.bookmarks.each do |rk|
      ret << Annotation.new("#{rk.id}", "bookmark", rk.start_sec, rk.end_sec, "#{rk.title} #{rk.body}","bookmark")
    end
    ret.sort{ |a, b| a.start_sec<=>b.start_sec}
  end

  def get_keywords(db_name)
    voice_log_id = self.id

    sql = "";
    sql += "select ";
    sql += " r.id as id, r.voice_log_id as voice_log_id, r.start_msec as start_msec, r.end_msec as end_msec, ";
    sql += " r.keyword_id as keyword_id, k.keyword_type as keyword_type, k.name as keyword_name, ";
    sql += " kgm.keyword_group_id as keyword_group_id, kg.name as keyword_group_name, r.edit_status as edit_status ";
    sql += "from "+db_name+" r ";
    sql += "left join keywords k on r.keyword_id = k.id ";
    sql += "left join keyword_group_maps kgm on kgm.keyword_id = r.keyword_id ";
    sql += "left join keyword_groups kg on kgm.keyword_group_id = kg.id ";
    sql += "where r.voice_log_id = #{voice_log_id} ";
    sql += (db_name == 'edit_keywords' ? "and r.edit_status != 'd' " : "and r.edit_status is null ");
    sql += "order by start_msec ";
    
    if db_name == 'edit_keywords'
      return EditKeyword.find_by_sql(sql)
    else
      return ResultKeyword.find_by_sql(sql);
    end
  end
  
  def have_transfered_call?(transfer_count=nil)
    call_id = self.call_id
    if transfer_count.nil?
      #tf_count = VoiceLogTemp.where({:ori_call_id => call_id}).count
      tf_count = VoiceLogCounter.where(:voice_log_id => self.id).first.transfer_call_count.to_i rescue 0      
    else
      tf_count = transfer_count.to_i
    end
    return (not (tf_count == 0))
  end
  
  def transfer_calls
    
    calls = []
    call_id = self.call_id
    
    vcs = VoiceLogTemp.where({:ori_call_id => call_id })
    unless vcs.empty?
      vcs.each do |v|
        calls << v
        trans_call = [] #v.transfer_calls
        calls = calls.concat(trans_call) unless trans_call.empty?
      end
      trans_call = nil
      vcs = nil
    end
    
    return calls
    
  end
  
  def transfer_call_count
    tf_count = VoiceLogCounter.where(:voice_log_id => self.id).first.transfer_call_count.to_i rescue 0
    #tf_count = transfer_calls.length.to_i
    return tf_count
  end

  def transfer_call_count_by_type
    v = VoiceLogTemp.select("count(id) as total,sum(if(call_direction='i',1,0)) as total_in,sum(if(call_direction='o',1,0)) as total_out,sum(duration) as duration").where({:ori_call_id => self.call_id }).first
    if v.nil?
      return {:total => 0, :total_in => 0, :total_out => 0, :duration => 0 } 
    else
      return {:total => v.total.to_i, :total_in => v.total_in.to_i, :total_out => v.total_out.to_i, :duration => v.duration.to_i } 
    end 
  end
 
  def transfer_keywords_count_by_type
    result = {:total => 0, :total_ng => 0, :total_must => 0 }
    
    voice_logs = VoiceLogTemp.select("id").where({ :ori_call_id => self.call_id }).all
    unless voice_logs.empty?
      voice_logs_id = (voice_logs.map { |v| v.id }).join(",")
      
      sql1 = "SELECT " 
      sql1 << "SUM(IF(k.keyword_type='n',1,0)) AS ngword, "
      sql1 << "SUM(IF(k.keyword_type='m',1,0)) AS mustword "
      sql1 << "FROM result_keywords r JOIN keywords k "
      sql1 << "ON r.keyword_id = k.id "
      sql1 << "WHERE r.edit_status is null and k.deleted = false and r.voice_log_id in (#{voice_logs_id}) "
                
      sql2 = "SELECT "
      sql2 << "SUM(IF(k.keyword_type='n',1,0)) AS ngword, "
      sql2 << "SUM(IF(k.keyword_type='m',1,0)) AS mustword "
      sql2 << "FROM edit_keywords e JOIN keywords k "
      sql2 << "ON e.keyword_id = k.id "
      sql2 << "WHERE e.edit_status in ('n','e') and k.deleted = false and e.voice_log_id in (#{voice_logs_id}) "
      
      sql = "SELECT SUM(r.ngword) AS ngword, SUM(r.mustword) AS mustword "
      sql << "FROM ((#{sql1}) UNION (#{sql2})) r "
      
      x = ResultKeyword.find_by_sql(sql).first 
      result = {
          :total => x.mustword.to_i + x.ngword.to_i,
          :total_ng => x.ngword.to_i, 
          :total_must => x.mustword.to_i 
      }
    end 
    return result
  end
  
  def update_customer_call(customer_id=0)
    
    voice_log_id = self.id
    
    c = VoiceLogCustomer.where(:voice_log_id => self.id).first
    if c.nil? and customer_id > 0
      VoiceLogCustomer.create({:voice_log_id => voice_log_id, :customer_id => customer_id })
    else
      if customer_id <= 0
        VoiceLogCustomer.delete(c) 
      else
        c.update_attributes({:voice_log_id => voice_log_id, :customer_id => customer_id })
      end
    end
    
  end
 
end
