class Did < ActiveRecord::Base
  
  has_paper_trail
  
  belongs_to  :extension, inverse_of: :dids

  validates 	:number,
                presence: true,
                length: {
                  minimum: 5,
                  maximum: 10
                }
                
  validates_uniqueness_of :number,
                allow_blank: false,
                allow_nil: false
  
  def self.remove_unused_records
    ids = find_unknow_extension
    unless ids.empty?
      ids.each do |id|
        Did.where(id: id).delete
      end
    end
  end
  
  private
  
  def self.find_unknow_extension
    sql =  " SELECT id FROM dids d"
    sql << " LEFT JOIN extensions e ON d.extension_id = e.id"
    sql << " WHERE e.id IS NULL"
    result = ActiveRecord::Base.connection.select_all(sql)
    return result.map { |d| d["id"].to_i }
  end
  
end
