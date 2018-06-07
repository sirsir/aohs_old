class TableHeader
  
  # To provide header details for creart table
  # in xlxs or html format
  # --
  
  def initialize    
    @criteria = []
    @headers = []
    @opts = {} unless defined? @opts
    @styles = []
  end
  
  def headers
    return @headers
  end
  
  def row_count
    return @headers.length
  end
  
  def add_header(cols, row_at, col_at)
    if @headers[row_at].nil?
      @headers[row_at] = [] 
    end
    row = @headers[row_at]
    row.insert(col_at, *cols)
  end
  
  def add_form_category_headers(plan)
    @criteria = plan.criteria      
    build_evaluation_form_headers
  end
  
  def to_xlsx_headers
    
    # To generate array for axlsx to create excel file
    
    headers     = []
    spancells   = []
    row_count   = @headers.length
    col_count   = 0
    spans       = []
    
    row_count.times {
      headers     << []
      spancells   << []  
    }
    
    @headers.each_with_index do |row, i|
      
      # STDOUT.puts "[xlsx] : R#{i}"
      
      r_at = i
      c_at = 0
      
      row.each_with_index do |col, j|
        
        # STDOUT.puts "[xlsx] : R#{i} C#{j}, #{col.inspect}"
        
        lst = spancells[r_at].select { |c| c >= c_at }
        unless lst.empty?
          lst.each do |m|
           if m <= c_at
             c_at += 1
           else
             break
           end
          end
        end
        
        # set cell
        headers[r_at][c_at] = col[:title] 
        
        # set rowspan
        if col[:rowspan] > 1
          (col[:rowspan]).times do |y|
            next if y == 0
            spancells[r_at + y] << c_at
            spancells[r_at + y] = spancells[r_at + y].sort
          end
          spans << [r_at,c_at,r_at+(col[:rowspan]-1),c_at]
        end
        
        if col[:colspan] > 1
          spans << [r_at,c_at,r_at,c_at + (col[:colspan] - 1)]
        end
        
        c_at += col[:colspan]
        
      end
      col_count = [c_at,col_count].sort.last
    end
    
    # set last cells
    headers.each do |r|
      if r.length < col_count
        r[col_count-1] = nil
      end
    end
    
    #STDOUT.puts "[xlsx] Result: #{headers.inspect}"
    #STDOUT.puts "[xlsx] Span: #{spans.inspect}"
    
    return headers, spans
    
  end
  
  protected
  
  # [Evaluation Form Headers]
  # To create/build evaluation form headers
  # for html and ms excel format
  
  def build_evaluation_form_headers
    
    ncols, nrows = build_header_ds

    unless @headers.empty?  
      @headers.each do |hrow|
        hrow = hrow.flatten
      end  
      update_span_colrow
    end
    
  end

  def build_header_ds(node=nil, nlevel=0)
    
    nodes = (node.nil? ? @criteria : node[:childs])
    ncols = 0
    nrows = 0
    
    unless nodes.empty?
      cols = []
      row_no = nlevel
      @headers[row_no] = [] if @headers[row_no].nil?
      
      nodes.each_with_index do |node, i|
        xcols, xrows = build_header_ds(node, row_no + 1)
        col = {
          title: node[:name],
          colspan: xcols,
          rowspan: 1
        }
        cols.push(col)
        ncols = ncols + xcols + 1
      end
      
      @headers[row_no].concat(cols)
    end
    
    return ncols, nrows
  
  end
  
  def update_span_colrow
    
    row_count = @headers.length
    row_count = 1 if row_count <= 0

    @headers.each_with_index do |row, i|
      row.each do |col|
        col[:rowspan] = row_count if not col[:rowspan].present? or col[:rowspan] > row_count
        if col[:colspan] <= 0 and col[:rowspan] == 1 and i < @headers.length
          col[:rowspan] = (i - @headers.length).abs
          col[:colspan] = 1 if col[:colspan] <= 0
        end
      end
    end
    
  end
  
  # end of build evaluation form header
  # [Evaluation Form Headers]

end