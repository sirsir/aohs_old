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

  belongs_to :user, :foreign_key => "agent_id",:conditions => ["flag = ?",false]
  has_one :voice_log_counter, :foreign_key => "voice_log_id"

  has_one :voice_log_customer, :class_name => "VoiceLogCustomer"
  has_one :customer, :class_name => "Customers" ,:through => :voice_log_customer

  has_many :result_keywords,:conditions => 'edit_status is null',:order => "start_msec"
  has_many :edit_keywords,:conditions => "edit_status != 'd'",:order => "start_msec"
  has_many :call_informations , :foreign_key => "voice_log_id",:order => "start_msec"
  has_many :bookmarks, :class_name => "CallBookmark",:order => "start_msec"

  def disposition
      @@disposition = self.voice_file_url
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
  
  named_scope :agents, lambda{ |agent_ids|
    if agent_ids.class == String
      { :conditions => ["agent_id = :agent_id", {:agent_id=>agent_ids}] }
    else
      { :conditions => ["agent_id in (:agent_ids)", {:agent_ids=>agent_ids}] }
    end
  }
  named_scope :date, lambda { |start_date|
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

  def get_result_keywords
    voice_log_id = self.id

    sql = "";
    sql += "select ";
    sql += " r.id as id, r.voice_log_id as voice_log_id, r.start_msec as start_msec, r.end_msec as end_msec, ";
    sql += " r.keyword_id as keyword_id, k.keyword_type as keyword_type, k.name as keyword_name, ";
    sql += " kgm.keyword_group_id as keyword_group_id, kg.name as keyword_group_name, r.edit_status as edit_status ";
    sql += "from result_keywords r ";
    sql += "left join keywords k on r.keyword_id = k.id ";
    sql += "left join keyword_group_maps kgm on kgm.keyword_id = r.keyword_id ";
    sql += "left join keyword_groups kg on kgm.keyword_group_id = kg.id ";
    sql += "where r.voice_log_id = #{voice_log_id} ";
    sql += "and r.edit_status is null ";
    sql += "order by start_msec ";

    return ResultKeyword.find_by_sql(sql);
  end

  def get_edit_keywords
    voice_log_id = self.id

    sql = "";
    sql += "select ";
    sql += " r.id as id, r.voice_log_id as voice_log_id, r.start_msec as start_msec, r.end_msec as end_msec, ";
    sql += " r.keyword_id as keyword_id, k.keyword_type as keyword_type, k.name as keyword_name, ";
    sql += " kgm.keyword_group_id as keyword_group_id, kg.name as keyword_group_name, r.edit_status as edit_status ";
    sql += "from edit_keywords r ";
    sql += "left join keywords k on r.keyword_id = k.id ";
    sql += "left join keyword_group_maps kgm on kgm.keyword_id = r.keyword_id ";
    sql += "left join keyword_groups kg on kgm.keyword_group_id = kg.id ";
    sql += "where r.voice_log_id = #{voice_log_id} ";
    sql += "and r.edit_status != 'd' ";
    sql += "order by start_msec ";

    return EditKeyword.find_by_sql(sql);
  end
  
end
