class FaqTag < ActiveRecord::Base
  
  strip_attributes only: [:tag_name]
  
  belongs_to :faq_question
  
  scope :only_tag, ->{
    where(tag_type: 'Tag')
  }
  
  scope :find_by_name, ->(name){
    where(tag_name: name)  
  }
  
  scope :order_by_default, ->{
    order(tag_name: :asc)  
  }
  
  def self.all_tags
    select("DISTINCT tag_name").only_tag.all.map { |t| t.tag_name }
  end
  
  def self.new_tag(params)
    new_record = new(params)
    new_record.tag_type = 'Tag'
    return new_record
  end
  
end
