class EvaluationQuestionGroup < ActiveRecord::Base
  
  has_paper_trail
  
  has_many    :evaluation_questions, foreign_key: :question_group_id

  default_value_for   :flag,  ""
  
  strip_attributes  allow_empty: true,
                    collapse_spaces: true
  
  validates   :title,
                presence: true,
                uniqueness: true,
                length: {
                  minimum: 1,
                  maximum: 150
                }

  scope :not_deleted, ->{
    where.not(flag: DB_DELETED_FLAG)  
  }
  
  scope :order_by_default, ->{
    order(:order_no, :title)
  }
  
  scope :find_name, ->(name){
    where(title: name)  
  }
  
  def self.select_options(opts={})
    # select current list
    list = not_deleted.all.to_a.select { |s| s.have_questions? }
    # add specific value
    if opts[:includes].present?
      tlist = find_name(opts[:includes]).all
      unless tlist.empty?
        list = list.concat(tlist.to_a)
      end
    end
    # add specific value
    if opts[:include_id].present?
      tlist = where(id: opts[:include_id]).all
      unless tlist.empty?
        list = list.concat(tlist.to_a)
      end
    end
    list = list.sort { |a,b| a.title <=> b.title }
    return list.map { |g| [g.title, g.id] }  
  end
  
  def self.auto_update_order_no
    sql = []
    sql << "SELECT c.question_group_id, c.name, c.order_no"
    sql << "FROM evaluation_criteria c"
    sql << "WHERE c.item_type = 'category' AND flag <> 'D'"
    sql << "GROUP BY c.question_group_id"
    sql << "ORDER BY order_no, AVG(c.order_no), c.name"
    result = ActiveRecord::Base.connection.select_all(sql.join(" "))
    EvaluationQuestionGroup.all.each do |g|
      result.each_with_index do |rs, i|
        if rs["question_group_id"].to_i == g.id
          g.order_no = (i + 1) * 100
          break
        else
          g.order_no = MAX_ORDERNO_INT
        end
      end
      g.save
    end
  end
  
  def self.create_if_not_exist(title)
    eqg = find_name(title).first
    if eqg.nil?
      eqg = EvaluationQuestionGroup.new
      eqg.title = title
      eqg.do_init
    else
      eqg.do_undodelete
    end
    if eqg.save
      return eqg 
    end
    return eqg 
  end
  
  def deleted?
    self.flag == DB_DELETED_FLAG
  end
  
  def do_init
    self.flag = ""
    self.order_no = 0
  end

  def do_undodelete
    self.flag = ""
  end
  
  def have_questions?
    return (question_count > 0)
  end
  
  def question_count
    return self.evaluation_questions.not_deleted.count(0)
  end
  
end
