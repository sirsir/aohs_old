class CsvReport
  
  def generate_report(report,op={})
    
    lines = []
    
    # header  
    
    lines << report[:title] unless report[:title].blank?
    lines << report[:desc] unless report[:desc].nil?

    # cols name
    
    if report[:cols][:multi] == true
      if not report[:cols][:subs].nil? and not report[:cols][:subs].empty?
        if not report[:cols][:csv].nil?
          lines << (report[:cols][:csv].map { |c| "\"#{c}\"" }).join(',')  
        end      
      end
    else
      lines << (report[:cols][:cols].map { |c| "\"#{c[0]}\"" }).join(',')      
    end

    # body
    
    unless report[:data].blank?
      report[:data].each do |l|
        lines << (l.map { |r| "\"#{r}\""}).join(',')
      end
      
      if not report[:summary].nil?
        report[:summary].each_with_index do |row,j|
          row = row.map { |b| "\"#{b}\""} 
          s = report[:cols][:summary][j][0]
          if not s.nil?
            lines << add_empty_cells('',s[2].to_i-0).concat(row).join(',')
          else
            lines << row.join(',')
          end
        end
      end
       
    else
      lines << "No record found."     
    end 

    return lines.join("\r\n"), mkfname(report[:fname])
    
  end
  
  def add_empty_cells(name="",n=0)
    cells = []
    if n > 0
      n.times do 
        cells << "#{name}"
      end
    end
    return cells
  end
      
  def mkfname(filename="unknonCsvFilename")
    return "#{Time.new.strftime("%Y%m%d%H%M%S")}_#{filename}.csv"
  end
  
end