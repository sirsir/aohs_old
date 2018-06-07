class FaqAnswer < ActiveRecord::Base
  
  belongs_to :faq_question

  scope :not_deleted, -> {
    where.not({flag: DB_DELETED_FLAG})
  }
  
  scope :order_by_stat, ->{
    order(created_at: :desc)
  }
  
  scope :content_not_blank, ->{
    where("content IS NOT NULL and LENGTH(content) > 1")
  }
  
end
