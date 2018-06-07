class AnalyticTemplate < ActiveRecord::Base

  strip_attributes  allow_empty: true,
                    collapse_spaces: true
                    
  has_many :analytic_patterns
  
  scope :template_options, ->{
    select([:id, :title]).order(:title)
  }
  
  def update_text_match(texts)
    self.analytic_patterns.match_text.delete_all
    texts.each do |text|
      text = text.strip.chomp
      next if text.empty?
      pat = self.analytic_patterns.new
      pat.pattern = text
      pat.pattern_type = "match"
      pat.save
    end
  end

  def update_text_similar(texts)
    self.analytic_patterns.similar_text.delete_all
    texts.each do |text|
      text = text.strip.chomp
      next if text.empty?
      pat = self.analytic_patterns.new
      pat.pattern = text
      pat.pattern_type = "similar"
      pat.save
    end
  end
  
end
