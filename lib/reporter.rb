
class Reporter

 require 'java'
 require "#{RAILS_ROOT}/vendor/plugins/IText_pdf/iText-2.1.7.jar"
 include Format

 include_class "java.io.OutputStream"
 include_class "java.io.ByteArrayOutputStream"
 include_class "java.io.IOException"
 include_class "java.io.File"
 include_class "java.awt.Color"
 include_class("java.lang.String") { |package, name| "J" + name }
 include_class "com.lowagie.text.Element"
 include_class "com.lowagie.text.pdf.PdfWriter"
 include_class "com.lowagie.text.pdf.PdfPageEvent"
 include_class "com.lowagie.text.Document"
 include_class "com.lowagie.text.Phrase"
 include_class "com.lowagie.text.Paragraph"
 include_class "com.lowagie.text.PageSize"
 include_class "com.lowagie.text.Chunk"
 include_class "com.lowagie.text.Font"
 include_class "com.lowagie.text.Image"
 include_class "com.lowagie.text.pdf.BaseFont"
 include_class "com.lowagie.text.pdf.PdfPTable"
 include_class "com.lowagie.text.pdf.PdfPCell"
 include_class "com.lowagie.text.HeaderFooter"

 DEFAULT_REPORT_FONT_NORMAL_1 = "#{RAILS_ROOT}/vendor/plugins/IText_pdf/Fonts/ANGSA.TTF"
 DEFAULT_REPORT_FONT_NORMAL_2 = "#{RAILS_ROOT}/vendor/plugins/IText_pdf/Fonts/CORDIA.TTF"
 DEFAULT_REPORT_FONT_BOLD_1 = "#{RAILS_ROOT}/vendor/plugins/IText_pdf/Fonts/CORDIAB.TTF"
 DEFAULT_FONT_SIZE = 12
 DEFAULT_PAPER_SIZE = "A4"
 DEFAULT_LOGO_PATH = "#{Rails.public_path}/images/reports/"
 BREAK_LINE = "\n"

 # generate
 # params ->
 
 def generate_monthly_report(dataset,report_type,report_type2,limit_c)

   m = ByteArrayOutputStream.new()

   document=Document.new(PageSize.getRectangle(DEFAULT_PAPER_SIZE).rotate())

   norf = BaseFont.createFont(DEFAULT_REPORT_FONT_NORMAL_2,"Identity-H",true)
   nf = Font.new(norf, DEFAULT_FONT_SIZE)
   boldf = BaseFont.createFont(DEFAULT_REPORT_FONT_BOLD_1,"Identity-H",true)
   bf = Font.new(boldf,DEFAULT_FONT_SIZE,1)
   hf = Font.new(boldf,DEFAULT_FONT_SIZE,1)
   hf2 = Font.new(boldf,DEFAULT_FONT_SIZE+3,1)
   
   head_color = Color.new(192,192,192);
   hstdate = dataset[:st_date]
   hetdate = dataset[:fi_date]
   rw = []

   image_path = Configuration.find(:first,:conditions=>{:variable=>'reportHeaderLogo'}).default_value
   p = Paragraph.new("",hf)
   unless image_path.blank?
      image_path = "#{DEFAULT_LOGO_PATH}#{image_path}"
      logo = Chunk.new(Image.getInstance(image_path), 0, -15);
	    p.add(logo)
      p.add("  ")
   end

   report_title = Configuration.find(:first,:conditions=>{:variable=>'reportHeaderName'}).default_value
   p.add(report_title + BREAK_LINE);

   # define report Header & Footer
   
   report_name = add_spaces(dataset[:name],100)
   report_date_period = add_spaces("#{dataset[:title1]}   #{dataset[:period_rank]}",80)
   
   p_header_sub = Paragraph.new("",hf2)
   p_header_sub.add(report_name + BREAK_LINE)
   p_header_sub.add(report_date_period)
   p_header_sub.setSpacingAfter(0)
   p.add(p_header_sub)
   
   limit_cell = 0
   limit_cell_width = 0
   report_type = dataset[:display_type]
   if report_type2 == 'calls' || report_type2 == 'keywords'
   case report_type
     when "weekly"
		#	p.add("                                                                                       Statistics Weekly Agent ("+report_type2+") Report\n")
      #p.add("                                                                                          From "+hstdate + " to " + hetdate)
      rw << 10
      rw << 25
      rw << 60
      rw << 20
      limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_weekly'}).default_value.to_i : limit_c.to_i
      if limit_cell <= 7
        limit_cell_width = 20
      elsif limit_cell <= 12
        limit_cell_width = 10
      else
        limit_cell_width = 5
      end
      (1..limit_cell).each do |lm|
          rw << limit_cell_width
      end
      when "monthly"
      #p.add("                                                                                       Statistics Monthly Agent ("+report_type2+") Report\n")
      #p.add("                                                                                          From "+hstdate + " to " + hetdate)
      rw << 10
      rw << 25
      rw << 60
      rw << 20
      limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_monthly'}).default_value.to_i : limit_c.to_i
      if limit_cell <= 7
        limit_cell_width = 20
      elsif limit_cell <= 12
        limit_cell_width = 10
      else
        limit_cell_width = 5
      end
      (1..limit_cell).each do |lm|
          rw << limit_cell_width
      end
      when "daily"
      #p.add("                                                                                       Statistics Daily Agent ("+report_type2+") Report\n")
      #p.add("                                                                                          From "+hstdate + " to " + hetdate)
      rw << 10
      rw << 25
      rw << 60
      rw << 20
      limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_daily'}).default_value.to_i : limit_c.to_i - 1
      STDERR.puts limit_cell
      if limit_cell <= 7
        limit_cell_width = 20
      elsif limit_cell <= 12
        limit_cell_width = 10
      else
        limit_cell_width = 9
      end
      (0..limit_cell).each do |lm|
          rw << limit_cell_width
      end
    end
   else
      case report_type
      when "weekly"
		#	p.add("                                                                                       Statistics Weekly Keywords Report\n")
      #p.add("                                                                                         From"+hstdate + " to " + hetdate)
      rw << 10
      rw << 20
      rw << 80
      rw << 20
      limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_weekly'}).default_value.to_i : limit_c.to_i
      if limit_cell <= 7
        limit_cell_width = 20
      elsif limit_cell <= 12
        limit_cell_width = 10
      else
        limit_cell_width = 5
      end
      (1..limit_cell).each do |lm|
          rw << limit_cell_width
      end
      when "monthly"
      #p.add("                                                                                        Statistics Monthly Keywords Report\n")
      #p.add("                                                                                         From "+hstdate + " to " + hetdate)
      rw << 10
      rw << 20
      rw << 80
      rw << 20
      limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_monthly'}).default_value.to_i : limit_c.to_i 
      if limit_cell <= 7
        limit_cell_width = 20
      elsif limit_cell <= 12
        limit_cell_width = 10
      else
        limit_cell_width = 5
      end
      (1..limit_cell).each do |lm|
          rw << limit_cell_width
      end
      when "daily"
      #p.add("                                                                                         Statistics Daily Keywords Report\n")
      #p.add("                                                                                         From "+hstdate + " to " + hetdate)
      rw << 10
      rw << 15
      rw << 67
      rw << 15
      limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_daily'}).default_value.to_i  : limit_c.to_i - 1
      STDERR.puts 'daily limit cell is '+limit_cell.to_s
      if limit_cell <= 7
        limit_cell_width = 20
      elsif limit_cell <= 12
        limit_cell_width = 10
      else
        limit_cell_width = 10
      end
      (0..limit_cell).each do |lm|
          rw << limit_cell_width
      end
   end
   end
    header = HeaderFooter.new(p, false);
    header.setBorder(0)
    header.setAlignment(Element.ALIGN_LEFT)
    footer = HeaderFooter.new(Phrase.new("Page: ",nf),true);
    footer.setBorder(0)
    # end define header & Footer
  
    # set multi column table header
    cols = dataset[:cols1].to_ary.length + dataset[:cols_labels].length
    h_keyword_table = PdfPTable.new(cols)
    keyword_table = PdfPTable.new(cols)
    keyword_table.setWidths(rw.to_java(Java::int))
    keyword_table.setWidthPercentage(100);
    h_keyword_table.setWidths(rw.to_java(Java::int))
    h_keyword_table.setWidthPercentage(100);
    # end set multi column table header
   
    # define table header
    dataset[:cols1].to_ary.each do |col|
             header1 = PdfPCell.new(Paragraph.new(col,nf))
             header1.setRowspan(2)
             header1.setHorizontalAlignment(Element.ALIGN_CENTER)
             header1.setVerticalAlignment(Element.ALIGN_MIDDLE)
             header1.setBackgroundColor(head_color);
             h_keyword_table.addCell(header1)
    end
	 dataset[:cols_count].each_with_index do |cc,ind|
	 header2 = PdfPCell.new(Paragraph.new(dataset[:cols2][ind].to_s,nf))
	 header2.setColspan(cc)
	 header2.setBackgroundColor(head_color);
	 header2.setHorizontalAlignment(Element.ALIGN_CENTER)
	 header2.setVerticalAlignment(Element.ALIGN_MIDDLE)
	 header2.setPaddingBottom(10)
	 h_keyword_table.addCell(header2)
	 end
	dataset[:cols_labels].to_ary.each do |col|
	
	  header1 = PdfPCell.new(Paragraph.new(col.to_s,nf))
	  header1.setBackgroundColor(head_color);
	  header1.setHorizontalAlignment(Element.ALIGN_CENTER)
	  header1.setVerticalAlignment(Element.ALIGN_MIDDLE)
	  header1.setPaddingBottom(10)
	  h_keyword_table.addCell(header1)
	end
  header_cell = PdfPCell.new(h_keyword_table)
  header_cell.setColspan(cols)
  keyword_table.addCell(header_cell)
     keyword_table.setHeaderRows(1) #set head cell
  # end define table header
  # define details data
            STDERR.puts 'write report details'
           # STDERR.puts dataset[:details]
            dataset[:details].to_ary.each do |dt|
               c_no = PdfPCell.new(Paragraph.new(dt[0].to_s,nf))
               c_no.setHorizontalAlignment(Element.ALIGN_CENTER)
               c_no.setPaddingBottom(7)
               keyword_table.addCell(c_no)
               c_name = PdfPCell.new(Paragraph.new(dt[1].to_s,nf))
               c_name.setPaddingBottom(7)
               keyword_table.addCell(c_name)
               c_type = PdfPCell.new(Paragraph.new(dt[2].to_s,nf))
               c_type.setPaddingBottom(7)
               keyword_table.addCell(c_type)
               c_total = PdfPCell.new(Paragraph.new(dt[3].to_s,nf))
               c_total.setHorizontalAlignment(Element.ALIGN_RIGHT)
               c_total.setPaddingBottom(7)
               keyword_table.addCell(c_total)
               (4..(dt.length - 1)).each do |i|
                 # STDERR.puts 'dt is '+dt[i].to_s
                   cells = PdfPCell.new(Paragraph.new(number_with_delimiter(dt[i]).to_s,nf))
                   cells.setHorizontalAlignment(Element.ALIGN_RIGHT)
                   cells.setPaddingBottom(7)
                   keyword_table.addCell(cells)
               end
             end
             #grand total
             unless dataset[:total].blank?
             gtotal = PdfPCell.new(Paragraph.new("Grand total",nf))
             gtotal.setColspan(3)
             gtotal.setHorizontalAlignment(Element.ALIGN_CENTER)
            # gtotal.setVerticalAlignment(Element.ALIGN_MIDDLE)
             gtotal.setPaddingBottom(7)
             gtotal.setBackgroundColor(head_color);
             keyword_table.addCell(gtotal)
             STDERR.puts 'write detail complete'
             STDERR.puts 'write grand total'
             dataset[:total].to_ary.each do |tt|
             cells = PdfPCell.new(Paragraph.new(number_with_delimiter(tt).to_s,nf))
                   cells.setHorizontalAlignment(Element.ALIGN_RIGHT)
                #   cells.setVerticalAlignment(Element.ALIGN_MIDDLE)
                   cells.setPaddingBottom(7)
                   cells.setBackgroundColor(head_color);
                   keyword_table.addCell(cells)
             end
             end

    #
    # write report
    writer=PdfWriter.getInstance(document,m)
    writer.closeStream = false
    document.setHeader(header)
    document.setFooter(footer)
    document.open()
    document.add(keyword_table)
    document.close
    fileinbytes = String.from_java_bytes(m.toByteArray())

    return fileinbytes
 end

  def generate_voice_report(dataset)

      m = ByteArrayOutputStream.new()
      font_path = RAILS_ROOT+"/vendor/plugins/IText_pdf/Fonts/"+"CORDIA.TTF"
      hfont_path = RAILS_ROOT+"/vendor/plugins/IText_pdf/Fonts/"+"CORDIAB.TTF"
      document=Document.new(PageSize.getRectangle("A4").rotate())
      bf = BaseFont.createFont(
        font_path,
        "Identity-H",
        true
      )
      hbf = BaseFont.createFont(hfont_path,"Identity-H",true)
      f = Font.new(bf, 12)
      hf = Font.new(hbf,12)
      hf2 = Font.new(hbf,14)
      head_color = Color.new(192,192,192);
      #rw = [7,20,10,13,13,12,40,10,12,12,12,30]
      rw = [7,20,10,13,13,12,40,10,12,12,12]
      image_path = Configuration.find(:first,:conditions=>{:variable=>'reportHeaderLogo'}).default_value
	    p = Paragraph.new("",Font.new(hbf,12,1))
      unless image_path.blank?
        image_path = "#{DEFAULT_LOGO_PATH}#{image_path}"  
        logo = Chunk.new(Image.getInstance(image_path), 0, -15);
	      p.add(logo)
        p.add("  ")
      end
      p.add(Configuration.find(:first,:conditions=>{:variable=>'reportHeaderName'}).default_value + "\n");
 
      p_header_sub = Paragraph.new("",hf2)
      p_header_sub.add(add_spaces(dataset[:name].to_s + " Report",110))
      p_header_sub.setSpacingAfter(0)
      p.add(p_header_sub)
               
      #p.add("                                                                                      "+dataset[:name].to_s+" Report\n")
      header = HeaderFooter.new(p, false);
      header.setBorder(0)
      header.setAlignment(Element.ALIGN_LEFT)
      footer = HeaderFooter.new(Phrase.new("Page : ",f),true);
      footer.setBorder(0)
      cols = dataset[:cols].to_ary.length
      keyword_table = PdfPTable.new(cols)
      keyword_table.setWidths(rw.to_java(Java::int))
      keyword_table.setWidthPercentage(100);

      dataset[:cols].to_ary.each do |col|
             header1 = PdfPCell.new(Paragraph.new(col,hf))
             header1.setHorizontalAlignment(Element.ALIGN_CENTER)
             header1.setVerticalAlignment(Element.ALIGN_MIDDLE)
             header1.setPaddingBottom(10)
             header1.setBackgroundColor(head_color);
             keyword_table.addCell(header1)
      end
      keyword_table.setHeaderRows(1)
     
      padding_bottom = 3
      padding_top = 2
      
      # To details report
     unless dataset[:details].empty?
       
     dataset[:details].to_ary.each do |dt|
               #STDERR.puts dt
               c_no = PdfPCell.new(Paragraph.new(dt[0].to_s,f))
               c_no.setHorizontalAlignment(Element.ALIGN_RIGHT)
               c_no.setPaddingBottom(padding_bottom)
               c_no.setPaddingTop(padding_top)
               keyword_table.addCell(c_no)
               st_time = PdfPCell.new(Paragraph.new(dt[1].to_s,f))
               st_time.setPaddingBottom(padding_bottom)
               st_time.setPaddingTop(padding_top)
               keyword_table.addCell(st_time)
               duration = PdfPCell.new(Paragraph.new(dt[2].to_s,f))
               duration.setPaddingBottom(padding_bottom)
               duration.setPaddingTop(padding_top)
               keyword_table.addCell(duration)
               ani = PdfPCell.new(Paragraph.new(dt[3].to_s,f))
               ani.setPaddingBottom(padding_bottom)
               ani.setPaddingTop(padding_top)
               keyword_table.addCell(ani)
               dnis = PdfPCell.new(Paragraph.new(dt[4].to_s,f))
               dnis.setPaddingBottom(padding_bottom)
               dnis.setPaddingTop(padding_top)
               keyword_table.addCell(dnis)
               ext = PdfPCell.new(Paragraph.new(dt[5].to_s,f))
               ext.setPaddingBottom(padding_bottom)
               ext.setPaddingTop(padding_top)
               ext.setHorizontalAlignment(Element.ALIGN_RIGHT)
               keyword_table.addCell(ext)
               agent = PdfPCell.new(Paragraph.new(dt[6].to_s,f))
               agent.setPaddingBottom(padding_bottom)
               agent.setPaddingTop(padding_top)
               keyword_table.addCell(agent)
               cd = PdfPCell.new(Paragraph.new(dt[7].to_s,f))
               cd.setHorizontalAlignment(Element.ALIGN_CENTER)
               cd.setPaddingBottom(padding_bottom)
               cd.setPaddingTop(padding_top)
               keyword_table.addCell(cd)
               (8..(dt.length-1)).each do |i|
                   cells = PdfPCell.new(Paragraph.new(number_with_delimiter(dt[i]).to_s,f))
                   cells.setHorizontalAlignment(Element.ALIGN_RIGHT)
                   cells.setPaddingBottom(padding_bottom)
                   cells.setPaddingTop(padding_top)
                   keyword_table.addCell(cells)
               end
               #customer = PdfPCell.new(Paragraph.new(dt[dt.length].to_s,f))
            #   customer = PdfPCell.new(Paragraph.new("xxx"))
               #customer.setPaddingBottom(7)
               #keyword_table.addCell(customer)
      end
      
      else
          c_no = PdfPCell.new(Paragraph.new("No record.",f))
          c_no.setHorizontalAlignment(Element.ALIGN_CENTER)
          c_no.setPaddingBottom(padding_bottom)
          c_no.setPaddingTop(padding_top)
          c_no.setColspan(11)
          keyword_table.addCell(c_no)  
      end
      # From details report
      # write report
        writer=PdfWriter.getInstance(document,m)
        writer.closeStream = false
        document.setHeader(header)
        document.setFooter(footer)
        document.open()
        document.add(keyword_table)
        document.close
        fileinbytes = String.from_java_bytes(m.toByteArray())

        return fileinbytes
      # ene write report
  end

  def generate_keyword_report(dataset)
      m = ByteArrayOutputStream.new()
      font_path = RAILS_ROOT+"/vendor/plugins/IText_pdf/Fonts/"+"CORDIA.TTF"
      hfont_path = RAILS_ROOT+"/vendor/plugins/IText_pdf/Fonts/"+"CORDIAB.TTF"
      document=Document.new(PageSize.getRectangle("A4").rotate())
      bf = BaseFont.createFont(
        font_path,
        "Identity-H",
        true
      )
      hbf = BaseFont.createFont(hfont_path,"Identity-H",true)
      f = Font.new(bf, 12)
      hf = Font.new(hbf,12)
      head_color = Color.new(192,192,192);
      rw = [7,80,20,15]
      keyword_header = JString.new(dataset[:lfhead].to_s)
      image_path = Configuration.find(:first,:conditions=>{:variable=>'reportHeaderLogo'}).default_value
 
	 p = Paragraph.new("",hf)
   unless image_path.blank?
     image_path = "#{DEFAULT_LOGO_PATH}#{image_path}"
   logo = Chunk.new(Image.getInstance(image_path), 0, -15);
	 p.add(logo)
     p.add("  ")
   end

   p.add(Configuration.find(:first,:conditions=>{:variable=>'reportHeaderName'}).default_value + "\n");
      p.add(add_spaces(dataset[:name].to_s + " Report\n",110))
      #p.add("                                                                                      "+dataset[:name].to_s+" Report\n")
      p.add(Chunk.new(keyword_header,f))
      header = HeaderFooter.new(p, false);
      header.setBorder(0)
      header.setAlignment(Element.ALIGN_LEFT)
      footer = HeaderFooter.new(Phrase.new("Page : ",f),true);
      footer.setBorder(0)
      cols = dataset[:hlist].to_ary.length
      keyword_table = PdfPTable.new(cols)
      keyword_table.setWidths(rw.to_java(Java::int))
      keyword_table.setWidthPercentage(100);

      dataset[:hlist].to_ary.each do |col|
             header1 = PdfPCell.new(Paragraph.new(col,hf))
             header1.setHorizontalAlignment(Element.ALIGN_CENTER)
             header1.setVerticalAlignment(Element.ALIGN_MIDDLE)
             header1.setPaddingBottom(10)
             header1.setBackgroundColor(head_color);
             keyword_table.addCell(header1)
      end
      keyword_table.setHeaderRows(1)
        # To details report
     dataset[:details].to_ary.each do |dt|
               #STDERR.puts dt
               c_no = PdfPCell.new(Paragraph.new(dt[0].to_s,f))
               c_no.setHorizontalAlignment(Element.ALIGN_RIGHT)
               c_no.setPaddingBottom(7)
            #   c_no.setUseAscender(5)
               keyword_table.addCell(c_no)
               agent_name = PdfPCell.new(Paragraph.new(dt[1].to_s,f))
               agent_name.setPaddingBottom(7)
              # agent_name.setUseAscender(5)
               keyword_table.addCell(agent_name)
               team_name = PdfPCell.new(Paragraph.new(dt[2].to_s,f))
               team_name.setPaddingBottom(7)
              # team_name.setUseAscender(5)
               keyword_table.addCell(team_name)
               cells = PdfPCell.new(Paragraph.new(number_with_delimiter(dt[3]).to_s,f))
               cells.setHorizontalAlignment(Element.ALIGN_RIGHT)
               cells.setPaddingBottom(7)
             #  cells.setUseAscender(5)
               keyword_table.addCell(cells)
      end
      # From details report
      # report total
         cell1 = PdfPCell.new(Paragraph.new("Grand total",hf))
                 cell1.setHorizontalAlignment(Element.ALIGN_CENTER)
                 cell1.setPaddingBottom(10)
                 cell1.setBackgroundColor(head_color);
                 cell1.setColspan(3)
                 keyword_table.addCell(cell1)
         cells = PdfPCell.new(Paragraph.new(number_with_delimiter(dataset[:total]).to_s,f))
                 cells.setHorizontalAlignment(Element.ALIGN_RIGHT)
                 cells.setPaddingBottom(10)
                 cells.setBackgroundColor(head_color);
                 keyword_table.addCell(cells)
      #
      # write report
        writer=PdfWriter.getInstance(document,m)
        writer.closeStream = false
        document.setHeader(header)
        document.setFooter(footer)
        document.open()
        document.add(keyword_table)
        document.close
        fileinbytes = String.from_java_bytes(m.toByteArray())
       # STDERR.puts RAILS_ROOT
        return fileinbytes
      # ene write report
  end

 # generate keywords report
 # params ->

 def generate_statistics_keyword(dataset,report_type,keyword_type,limit_c)

   m = ByteArrayOutputStream.new()
   document=Document.new(PageSize.getRectangle(DEFAULT_PAPER_SIZE).rotate())

   norf = BaseFont.createFont(DEFAULT_REPORT_FONT_NORMAL_2,"Identity-H",true)
   nf = Font.new(norf, DEFAULT_FONT_SIZE)
   boldf = BaseFont.createFont(DEFAULT_REPORT_FONT_BOLD_1,"Identity-H",true)
   bf = Font.new(boldf,DEFAULT_FONT_SIZE)
   hf = Font.new(boldf,DEFAULT_FONT_SIZE,1)
   hf2 = Font.new(boldf,DEFAULT_FONT_SIZE+3,1)
   
   head_color = Color.new(192,192,192);
   hstdate = dataset[:st_date]
   hetdate = dataset[:fi_date]

   rw = [] # table cols

   p = Paragraph.new("",hf)

   # report logo
   image_path = Configuration.find(:first,:conditions=>{:variable=>'reportHeaderLogo'}).default_value
   unless image_path.blank?
     image_path = "#{DEFAULT_LOGO_PATH}#{image_path}"
     logo = Chunk.new(Image.getInstance(image_path), 0, -15)
     p.add(logo)
     p.add("  ")
   end

   # report title
   rp_head_title = Configuration.find(:first,:conditions=>{:variable=>'reportHeaderName'}).default_value
   p.add("#{rp_head_title}" + BREAK_LINE);
   
   # -- define report Header & Footer

   limit_cell = 0
   limit_cell_width = 0

   report_name = add_spaces(dataset[:name],110)
   report_date_period = add_spaces("#{dataset[:title1]}   #{dataset[:period_rank]}",90)
   
   #p.add(report_name + BREAK_LINE)
   #p.add(report_date_period)
   
   p_header_sub = Paragraph.new("",hf2)
   p_header_sub.add(report_name + BREAK_LINE)
   p_header_sub.add(report_date_period)
   p_header_sub.setSpacingAfter(0)
   p.add(p_header_sub)
      
   report_type = dataset[:display_type]
   case report_type
     when 'daily'
       case keyword_type
         when 'group': rw.concat([10,40,25])  # no,name,total
         when 'name': rw.concat([10,40,17,24])  # no,name,group,type,total
       end
       limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_daily'}).default_value.to_i : limit_c.to_i.to_i - 1
       if limit_cell <= 7
         limit_cell_width = 20
       elsif limit_cell <= 15
         limit_cell_width = 20
       else
         limit_cell_width = 10
       end
       (0..limit_cell).each { |lm| rw << limit_cell_width }

     when 'weekly'
       case keyword_type
         when 'group': rw.concat([10,40,25])  # no,name,total
         when 'name': rw.concat([10,40,17,24])  # no,name,group,type,total
       end
       limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_weekly'}).default_value.to_i - 1 : limit_c.to_i.to_i - 1
       if limit_cell <= 7
         limit_cell_width = 20
       elsif limit_cell <= 15
         limit_cell_width = 20
       else
         limit_cell_width = 10
       end
       (0..limit_cell).each { |lm| rw << limit_cell_width }

     else  # monthly
       case keyword_type
         when 'group': rw.concat([10,40,25])  # no,name,total
         when 'name': rw.concat([10,40,17,24])  # no,name,group,type,total
        #when 'name': rw.concat([10,65,40,17,24])  # no,name,group,type,total
       end
       limit_cell = limit_c.to_i == 0 ? Configuration.find(:first,:conditions=>{:variable=>'number_of_monthly'}).default_value.to_i - 1 : limit_c.to_i.to_i - 1
        if limit_cell <= 7
          limit_cell_width = 20
        elsif limit_cell <= 15
          limit_cell_width = 20
        else
          limit_cell_width = 10
        end
        (0..limit_cell).each { |lm| rw << limit_cell_width }
      end
   
      header = HeaderFooter.new(p, false);
      header.setBorder(0)
      header.setAlignment(Element.ALIGN_LEFT)
      footer = HeaderFooter.new(Phrase.new("Page: ",nf),true);
      footer.setBorder(0)

    # -- end define header & Footer

    # -- set multi column table header

    cols = dataset[:cols1].to_ary.length + dataset[:cols_labels].length
   
    h_keyword_table = PdfPTable.new(cols)
    keyword_table = PdfPTable.new(cols)
    keyword_table.setWidths(rw.to_java(Java::int))
    keyword_table.setWidthPercentage(100);
    h_keyword_table.setWidths(rw.to_java(Java::int))
    h_keyword_table.setWidthPercentage(100);
    # end set multi column table header

    # define table header
    dataset[:cols1].to_ary.each do |col|
             header1 = PdfPCell.new(Paragraph.new(col,hf))
             header1.setRowspan(2)
             header1.setHorizontalAlignment(Element.ALIGN_CENTER)
             header1.setVerticalAlignment(Element.ALIGN_MIDDLE)
             header1.setBackgroundColor(head_color);
             h_keyword_table.addCell(header1)
    end
             dataset[:cols_count].each_with_index do |cc,ind|
             header2 = PdfPCell.new(Paragraph.new(dataset[:cols2][ind].to_s,hf))
             header2.setColspan(cc)
             header2.setBackgroundColor(head_color);
             header2.setHorizontalAlignment(Element.ALIGN_CENTER)
             header2.setVerticalAlignment(Element.ALIGN_MIDDLE)
             header2.setPaddingBottom(10)
             h_keyword_table.addCell(header2)
             end
            dataset[:cols_labels].to_ary.each do |col|
              header1 = PdfPCell.new(Paragraph.new(col.to_s,hf))
              header1.setBackgroundColor(head_color);
              header1.setHorizontalAlignment(Element.ALIGN_CENTER)
              header1.setVerticalAlignment(Element.ALIGN_MIDDLE)
              header1.setPaddingBottom(10)
              h_keyword_table.addCell(header1)
            end
              header_cell = PdfPCell.new(h_keyword_table)
              header_cell.setColspan(cols)
              keyword_table.addCell(header_cell)
              keyword_table.setHeaderRows(1) #set head cell
              # end define table header
              # define details data
            STDERR.puts 'write report details'
           # STDERR.puts dataset[:details]
            dataset[:details].to_ary.each do |dt|
               case keyword_type
               when 'group'
               c_no = PdfPCell.new(Paragraph.new(dt[0].to_s,nf))
               c_no.setHorizontalAlignment(Element.ALIGN_CENTER)
               c_no.setPaddingBottom(7)
               keyword_table.addCell(c_no)
               c_name = PdfPCell.new(Paragraph.new(dt[1].to_s,nf))
               c_name.setPaddingBottom(7)
               keyword_table.addCell(c_name)
               c_total = PdfPCell.new(Paragraph.new(dt[2].to_s,nf))
               c_total.setHorizontalAlignment(Element.ALIGN_RIGHT)
               c_total.setPaddingBottom(7)
               keyword_table.addCell(c_total)
               (3..(dt.length - 1)).each do |i|
                  # STDERR.puts 'dt is '+dt[i].to_s
                   cells = PdfPCell.new(Paragraph.new(number_with_delimiter(dt[i]).to_s,nf))
                   cells.setHorizontalAlignment(Element.ALIGN_RIGHT)
                   cells.setPaddingBottom(7)
                   keyword_table.addCell(cells)
               end
               when 'name'
               c_no = PdfPCell.new(Paragraph.new(dt[0].to_s,nf))
               c_no.setHorizontalAlignment(Element.ALIGN_CENTER)
               c_no.setPaddingBottom(7)
               keyword_table.addCell(c_no)
               c_name = PdfPCell.new(Paragraph.new(dt[1].to_s,nf))
               c_name.setPaddingBottom(7)
               keyword_table.addCell(c_name)
               c_group = PdfPCell.new(Paragraph.new(dt[3].to_s,nf))
               c_group.setPaddingBottom(7)
               keyword_table.addCell(c_group)
               c_type = PdfPCell.new(Paragraph.new(dt[2].to_s,nf))
               c_type.setPaddingBottom(7)
               keyword_table.addCell(c_type)
               c_total = PdfPCell.new(Paragraph.new(dt[4].to_s,nf))
               c_total.setHorizontalAlignment(Element.ALIGN_RIGHT)
               c_total.setPaddingBottom(7)
               keyword_table.addCell(c_total)
               (5..(dt.length - 1)).each do |i|
                  # STDERR.puts 'dt is '+dt[i].to_s
                   cells = PdfPCell.new(Paragraph.new(number_with_delimiter(dt[i]).to_s,nf))
                   cells.setHorizontalAlignment(Element.ALIGN_RIGHT)
                   cells.setPaddingBottom(7)
                   keyword_table.addCell(cells)
               end
            end
            end
             #grand total
             unless dataset[:total].blank?
             gtotal = PdfPCell.new(Paragraph.new("Grand total",bf))
             case keyword_type
             when 'group'
             gtotal.setColspan(2)
             when 'name'
             gtotal.setColspan(4)
             end
             gtotal.setHorizontalAlignment(Element.ALIGN_CENTER)
            # gtotal.setVerticalAlignment(Element.ALIGN_MIDDLE)
             gtotal.setPaddingBottom(7)
             gtotal.setBackgroundColor(head_color);
             keyword_table.addCell(gtotal)
             STDERR.puts 'write detail complete'
             STDERR.puts 'write grand total'
             dataset[:total].to_ary.each do |tt|
             cells = PdfPCell.new(Paragraph.new(number_with_delimiter(tt).to_s,bf))
                   cells.setHorizontalAlignment(Element.ALIGN_RIGHT)
                   #cells.setVerticalAlignment(Element.ALIGN_MIDDLE)
                   cells.setPaddingBottom(7)
                   cells.setBackgroundColor(head_color);
                   keyword_table.addCell(cells)
             end
             end
    
    # write report
    writer=PdfWriter.getInstance(document,m)
    writer.closeStream = false
    document.setHeader(header)
    document.setFooter(footer)
    document.open()
    document.add(keyword_table)
    document.close
    fileinbytes = String.from_java_bytes(m.toByteArray())
    STDERR.puts RAILS_ROOT
    return fileinbytes
   
 end

 def add_spaces(str,num_space,mode="left")

   spaces = ""
   num_space.times { spaces << " " }

   return "#{spaces}#{str}"

 end

end
