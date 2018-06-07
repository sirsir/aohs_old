class Tag < ActiveRecord::Base
  
  DEFAULT_PARENT_ID = 0
  
  has_paper_trail
  
  has_many     :taggings
  has_many     :childrens, class_name: "Tag", foreign_key: "parent_id"
  belongs_to   :parent, class_name: "Tag"
  
  before_save  :set_parent_id
  before_destroy :remove_subtags
  
  strip_attributes  only: [:name, :desc],
                    collapse_spaces: true

  default_value_for :parent_id, value: DEFAULT_PARENT_ID, allows_nil: false
  
  validates :name,
              presence: true,
              length: {
                minimum: 3,
                maximum: 45
              },
              uniqueness: {
                case_sensitive: false
              }
  
  validates :tag_code,
              allow_blank: true,
              allow_nil: true,
              uniqueness: {
                case_sensitive: false
              }

  validates :color_code,
                allow_blank: true,
                allow_nil: true,
                format: {
                  with: /#[a-zA-z0-9]{6}\z/,
                  message: 'invalid color code'
                }

  scope :only_category, ->{
    where({ parent_id: DEFAULT_PARENT_ID })
  }
  
  scope :without_subtags, ->{
    where({ parent_id: DEFAULT_PARENT_ID })
  }

  scope :order_by_default, ->{
    order(:name)
  }
  
  scope :order_by, ->(p) {
    incs      = []
    order_str = resolve_column_name(p)
    includes(incs).order(order_str)
  }
  
  scope :tag_like, ->(p){
    
    # use exist for sub tags
    sql = " SELECT 1 FROM tags t1 LEFT JOIN tags t2 ON t1.id = t2.parent_id"
    sql << " WHERE tags.id = t1.id"
    sql << " AND (t1.name LIKE '%#{p}%' OR t2.name LIKE '%#{p}%')"
    
    where("EXISTS (#{sql})")
  }
  
  scope :defined_color, ->{
    where("color_code IS NOT NULL AND color_code <> ''")  
  }

  def display_color_code
    if self.color_code.nil? or self.color_code.empty?
      return "#FFFFFF"
    else
      return self.color_code
    end
  end
  
  def sub_tags
    
    unless defined? @sub_tags
      @sub_tags = self.childrens.order("name").all
    end
    
    @sub_tags
    
  end
  
  def sub_tags_list
    
    return (sub_tags.map { |t| t.name }).join(", ")
  
  end
  
  def remove_subtags
    
    stgs = sub_tags
    unless stgs.empty?
      stgs.each { |t| t.delete }  
    end
    
    return true
  
  end
  
  def got_more_tags?
    
    return (self.childrens.count > 0)
    
  end
  
  def self.all_tag_options(opts={})
    
    tags = where({ parent_id: DEFAULT_PARENT_ID }).order("name")
    
    if opts[:exclude].present?
      tags = tags.where.not({ id: opts[:exclude] })
    end
    
    return tags.all.map { |o| [o.name,o.id] }
  
  end
  
  def self.tag_options_with_group
    data = []
    tags = only_category.order_by_default
    tags.each do |tag|
      x = [[tag.name,tag.id]].concat(tag.childrens.map { |t| [t.name,t.id] })
      data << [tag.name, x] 
    end
    return data
  end
  
  private

  def self.ransackable_scopes(auth_object = nil)
    
    %i(tag_like)
  
  end

  def self.resolve_column_name(str)
    
    unless str.empty?
      
    end
    
    return str
    
  end
  
  def set_parent_id
    
    self.parent_id = 0 if self.parent_id.to_i <= 0
    
  end
  
end
