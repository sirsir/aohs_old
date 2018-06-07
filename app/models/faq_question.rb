class FaqQuestion < ActiveRecord::Base

  strip_attributes  only: [:question, :content]
  
  has_many  :faq_tags
  has_many  :faq_answers
  
  scope :by_faq_id, ->(id){
    where(id: id)
  }
  
  scope :not_deleted, -> {
    where.not({flag: DB_DELETED_FLAG})
  }

  scope :order_by, ->(p) {
    incs = []
    order_str = resolve_column_name(p)
    includes(incs).order(order_str)
  }

  validates   :question,
                presence: true,
                length: {
                  minimum: 5,
                  maximum: 250
                }
  
  def self.create_source_file
    sfname = File.join(Rails.root,'tmp','faq_questions.json')
    rec_count = not_deleted.count(0)
    page_size = 100
    page_count = rec_count/page_size + 1
    page = 0
    sfile = File.open(sfname,"w")
    sfile.puts "["
    while page < page_count
      recs = not_deleted.limit(page_size).offset(page * page_size).order(:id).all
      recs.each do |r|
        t = { faq_id: r.id, question: r.question, tags: r.all_tags, updated_at: r.updated_at.to_formatted_s(:db) }
        sfile.puts t.to_json
      end
      page += 1
    end
    sfile.puts "]"
    sfile.close
    return sfname
  end
  
  def all_tags
    get_tags
  end
  
  def update_tags(tag_params)
    current_tags_id = []
    xtags = FaqTag.only_tag.where(faq_question_id: self.id)
    unless tag_params.empty?
      tag_params.uniq.each do |t|
        tr = xtags.find_by_name(t).first
        if tr.nil?
          tr = {
            faq_question_id: self.id,
            tag_name: t
          }
          tr = FaqTag.new_tag(tr)
          tr.save
        end
        current_tags_id << tr.id
      end
    end
    deleted_tags = xtags.where.not(id: current_tags_id)
    if deleted_tags.count(0) > 0
      deleted_tags.delete_all
    end
  end
  
  def do_delete
    self.flag = DB_DELETED_FLAG
  end
  
  def get_faq_answers(selected_id=nil)
    answers = self.faq_answers.not_deleted.limit(3).order_by_stat
    unless selected_id.nil?
      answers = answers.where(id: selected_id)
    end
    answers = answers.all.map { |a|
      { id: a.id, content: a.content.to_s, score: -1 }
    }
    return answers
  end
  
  private
  
  def get_tags
    tags = FaqTag.only_tag.where(faq_question_id: self.id).order(:tag_name).all
    return tags.map { |t| t.tag_name }
  end
  
  def self.resolve_column_name(str)
    str
  end
  
end
