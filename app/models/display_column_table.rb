class DisplayColumnTable < ActiveRecord::Base
  
  # flag
  # H = hidden column 
  # I = invisible column
  
  scope :by_table, ->(name){
    where(table_name: name).order(order_no: :asc, id: :desc)
  }
  
  scope :only_visible, ->{
    where.not(flag: 'I')  
  }
  
  scope :not_hidden, ->{
    where.not(flag: 'H')  
  }
  
  scope :for, ->(name){
    by_table(name).not_hidden
  }
  
  scope :table_list, ->{
    select("DISTINCT table_name").order("table_name")  
  }
  
  def self.clear_field_cache
    @@dsp_fields = {}
  end
  
  def self.get_field(target,field_name)
    if not defined? @@dsp_fields or @@dsp_fields[target].nil?
      @@dsp_fields = {} unless defined? @@dsp_fields
      @@dsp_fields[target] = DisplayColumnTable.by_table(target).all.to_a
    end
    i = @@dsp_fields[target].index { |x| x.variable_name == field_name or x.column_name == field_name }
    if (not i.nil?) and i >= 0
      return @@dsp_fields[target][i]
    else
      dobj = new
      dobj.init_new
      return dobj
    end
  end
  
  def init_new
    self.flag = 'H'
    self.searchable = 'N'
  end
  
  def title
    self.column_name
  end
  
  def field_name
    self.variable_name  
  end
  
  def css_classes
    cls = []
    if sortable?
      cls << "sort_dt order"
    else
      cls << "nosort"
    end
    return cls.join(" ")
  end
  
  def sortable?
    self.sortable == "Y"  
  end
  
  def hidden?
    self.flag == 'H'  
  end
  
  def searchable?
    self.searchable == "Y"
  end
  
  def enabled?
    not hidden?
  end
  
  def disable
    self.flag = 'H'  
  end
  
  def enable
    self.flag = ''  
  end
  
  def invisible
    self.flag = 'I'  
  end
  
  def invisible?
    self.flag == "I"
  end
  
  def visible
    if invisible? and not hidden?
      self.flag = ''
    end
  end
  
  def disable_search
    self.searchable = "N"  
  end
  
  def enable_search
    self.searchable = "Y" 
  end
  
  def sortable_status_name
    sortable? ? "Yes" : "No"
  end
  
end
