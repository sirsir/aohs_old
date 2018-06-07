class CustomDictionary < ActiveRecord::Base
  
  has_paper_trail
  
  strip_attributes    allow_empty: true,
                      collapse_spaces: true
  
  validates   :word,
                presence: true,
                uniqueness: true,
                length: {
                  minimum: 3,
                  maximum: 150
                }

  validates   :spoken_word,
                presence: true,
                uniqueness: true,
                length: {
                  minimum: 3,
                  maximum: 150
                }
                
  scope :order_by, ->(p){
    order_str = resolve_column_name(p)
    order(order_str)
  }
  
  def self.resolve_column_name(str)
    return str
  end
  
end
