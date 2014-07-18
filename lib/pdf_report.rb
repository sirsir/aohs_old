class PdfReport
  
  ITEXT_LIB_PATH = "#{RAILS_ROOT}/vendor/plugins/iText"
 
  require 'java'
  require "#{ITEXT_LIB_PATH}/iText-5.0.5.jar"
   
  include_class "java.io.OutputStream"
  include_class "java.io.ByteArrayOutputStream"
  include_class "java.io.IOException"
  include_class "java.io.File"
  include_class "java.awt.Color"
  include_class "java.awt.Graphics"
  include_class "java.awt.Graphics2D"
  include_class "com.itextpdf.text.Rectangle"
  include_class "java.awt.geom.Rectangle2D"
  include_class "java.awt.image.BufferedImage"
  include_class "java.awt.BasicStroke"
  include_class ("java.lang.String") { |package, name| "J" + name }
  include_class "com.itextpdf.text.Element"
  include_class "com.itextpdf.text.pdf.PdfWriter"
  include_class "com.itextpdf.text.pdf.PdfPageEvent"
  include_class "com.itextpdf.text.Document"
  include_class "com.itextpdf.text.DocumentException"
  include_class "com.itextpdf.text.pdf.PdfPageEventHelper"
  include_class "com.itextpdf.text.Phrase"
  include_class "com.itextpdf.text.Paragraph"
  include_class "com.itextpdf.text.PageSize"
  include_class "com.itextpdf.text.Chunk"
  include_class "com.itextpdf.text.Font"
  include_class "com.itextpdf.text.Image"
  include_class "com.itextpdf.text.pdf.ColumnText"
  include_class "com.itextpdf.text.pdf.BaseFont"
  include_class "com.itextpdf.text.pdf.PdfPTable"
  include_class "com.itextpdf.text.pdf.PdfPCell"
  include_class "com.itextpdf.text.pdf.DefaultFontMapper"
  include_class "com.itextpdf.text.pdf.PdfContentByte"
  include_class "com.itextpdf.text.BaseColor"
  
  DEFAULT_FONT_NORMAL1 = "#{ITEXT_LIB_PATH}/fonts/ANGSA.TTF"
  DEFAULT_ONT_BOLD1 = "#{ITEXT_LIB_PATH}/fonts/ANGSAB.TTF"
  DEFAULT_FONT_SIZE = 14
  DEFAULT_PAPER_SIZE = "A4"
  
  DOC_MRG_LEFT = 30
  DOC_MRG_RIGHT = 30
  DOC_MRG_TOP = 45
  DOC_MRG_BOTTOM = 25
  
  BREAK_LINE = "\n"
  REPORT_LOGO_FPATH = "#{Rails.public_path}/images/logo/#{Aohs::WEB_CLOGO}_report.png"
  CELL_PADDING = 4
  CELL_PADDING_TOP = -1
  CELL_PADDING_BOTTOM = 5
  
  def generate_report_one(report)
    
    m = ByteArrayOutputStream.new()
    
    document = Document.new(PageSize.getRectangle(DEFAULT_PAPER_SIZE).rotate(),DOC_MRG_LEFT,DOC_MRG_RIGHT,DOC_MRG_TOP + 30,DOC_MRG_BOTTOM)    
    
    # Style
    
    norf = BaseFont.createFont(DEFAULT_FONT_NORMAL1,"Identity-H",true)
    boldf = BaseFont.createFont(DEFAULT_ONT_BOLD1,"Identity-H",true)
    nf = Font.new(norf, DEFAULT_FONT_SIZE)
    bf = Font.new(boldf,DEFAULT_FONT_SIZE)
    hf = Font.new(boldf,DEFAULT_FONT_SIZE+2,1)
     
    headerfooter_event = HeaderFooter.new()
    headerfooter_event.report_title = report[:title_of]
    headerfooter_event.report_name = report[:title]
    headerfooter_event.report_description = report[:desc]
      
    cols_width = []
    cols_width = report[:cols][:cols].map { |c| c[2] }
            
    data_table = PdfPTable.new(report[:cols][:cols].length)
    data_table.setWidths(cols_width.to_java(Java::int))  
    data_table.setWidthPercentage(100)
    data_table.setSpacingBefore(0)
    data_table.setSpacingAfter(0)
       
    header_rows_count = 1
    if report[:cols][:multi] != true
      report[:cols][:cols].to_a.each_with_index do |col,i|
        STDOUT.puts "#{i} :: #{col[0]} :: #{cols_width[2]}"
        header1 = PdfPCell.new(Phrase.new(col[0],bf))
        header1.setHorizontalAlignment(Element.ALIGN_CENTER)
        header1.setVerticalAlignment(Element.ALIGN_MIDDLE)
        header1.setBackgroundColor(BaseColor.new(212,208,200));
        header1.setPaddingBottom(CELL_PADDING + 2)
        data_table.addCell(header1)
      end
    else
      header_rows_count = 2
      unless report[:cols][:subs].nil?  
        report[:cols][:subs].each_with_index do |rowths,j|
          rowths.to_a.each_with_index do |col,i|
            #STDOUT.puts "#{j}-#{i} :: #{col[0]} :: #{report[:cols][:cols][i][2]}"
            header1 = PdfPCell.new(Phrase.new(col[0].to_s,bf))
            if not col[1].nil? and col[1] > 1 
              header1.setRowspan(col[1])
            end
            if not col[2].nil? and col[2] > 1
              header1.setColspan(col[2])
            end
            header1.setHorizontalAlignment(Element.ALIGN_CENTER)
            header1.setVerticalAlignment(Element.ALIGN_MIDDLE)
            header1.setBackgroundColor(BaseColor.new(212,208,200));
            header1.setPaddingBottom(CELL_PADDING + 2)
            data_table.addCell(header1)
          end           
        end
        
      end
    end
    
    data_table.setHeaderRows(header_rows_count)

    unless report[:data].empty?
      STDOUT.puts "Building Data table .. #{report[:data].length}"
      report[:data].each_with_index do |row,r|
        rcolor = add_row_color(r)
        row.each_with_index do |cell,i|
          tcell = PdfPCell.new(Phrase.new(cell.to_s,nf))
          txt_align = Element.ALIGN_LEFT
          case report[:cols][:cols][i][1]
            when 'no'
              txt_align = Element.ALIGN_LEFT
            when 'date'
              txt_align = Element.ALIGN_LEFT           
            when 'int'
              txt_align = Element.ALIGN_RIGHT
            when 'sym'
              txt_align = Element.ALIGN_CENTER              
          end
          tcell.setHorizontalAlignment(txt_align)
          tcell.setPaddingBottom(CELL_PADDING_BOTTOM)
          tcell.setPaddingTop(CELL_PADDING_TOP)
          tcell.setBackgroundColor(rcolor);
          data_table.addCell(tcell)
        end
      end
      
      unless report[:summary].nil?
        report[:summary].each_with_index do |row,j|
          c_index = 0
          STDOUT.puts "Building Data summary .. #{j} : #{row.length}"
          row.each_with_index do |cell,i|
            tcell = PdfPCell.new(Phrase.new(cell.to_s,bf))
            txt_align = Element.ALIGN_LEFT
            if report[:cols][:cols][c_index]
              case report[:cols][:cols][c_index][1]
                when 'date'
                  txt_align = Element.ALIGN_LEFT
                when 'int'
                  txt_align = Element.ALIGN_RIGHT
                when 'grade'
                  txt_align = Element.ALIGN_CENTER
                when 'sym'
                  txt_align = Element.ALIGN_CENTER                     
              end
            end
            unless report[:cols][:summary][j][i].nil?
              if report[:cols][:summary][j][i][2].to_i > 1
                txt_align = Element.ALIGN_CENTER
                c_index += report[:cols][:summary][j][i][2].to_i + 1
                tcell.setColspan(report[:cols][:summary][j][i][2].to_i)
              end
            else
              c_index += 1
            end
            
            tcell.setBackgroundColor(BaseColor.new(206,206,206));
            tcell.setHorizontalAlignment(txt_align)
            tcell.setPaddingBottom(CELL_PADDING+2)
            data_table.addCell(tcell)  
            
          end
        end
      end
      
    else
      tcell = PdfPCell.new(Phrase.new("No record found.",nf))
      tcell.setHorizontalAlignment(Element.ALIGN_CENTER)
      tcell.setVerticalAlignment(Element.ALIGN_MIDDLE)
      tcell.setColspan(report[:cols][:cols].length)
      data_table.addCell(tcell)
    end
    
    # write report
    
    writer = PdfWriter.getInstance(document,m)
	  writer.setBoxSize("art",PageSize.getRectangle(DEFAULT_PAPER_SIZE).rotate());
    writer.setPageEvent(headerfooter_event);
    writer.closeStream = false
	  begin
	    document.open()
	    document.add(data_table)
	    document.close()
    rescue => e
      STDOUT.puts e.message
    end
    file_in_bytes = String.from_java_bytes(m.toByteArray())
     
    return file_in_bytes , mkfname(report[:fname])
    
  end

  def add_spaces(str,num=0)  
    spaces = ""
    num.times { spaces << " " }
    return "#{spaces}#{str}"   
  end

  def add_row_color(i=0)
    if(i.divmod(2)[1] == 0)
      return BaseColor.new(248,247,245)
    else 
      return BaseColor.new(255,255,255)
    end
  end
  
  def mkfname(filename="unknonPdfFilename")
    return "#{Time.new.strftime("%Y%m%d%H%M%S")}_#{filename}.pdf"
  end
  
  class HeaderFooter < PdfPageEventHelper
    
    attr_accessor :report_title, :report_name, :report_description

    @rect = nil
    @cb = nil
    @cb_top = 0
    @cb_bottom = 0
    @cb_left = 0
    @cb_right = 0
    @cb_center = 0
         
    def onOpenDocument(writer,document)
      
      @rect = writer.getBoxSize("art")
      @cb = writer.getDirectContent()
      
      @cb_top = @rect.getTop() - DOC_MRG_TOP
      @cb_bottom = @rect.getBottom()
      @cb_left = @rect.getLeft() + DOC_MRG_LEFT
      @cb_right = @rect.getRight() - DOC_MRG_RIGHT    
      @cb_center = (@cb_left + @cb_right)/2
      
      STDOUT.puts "OpenDocument:0"
      
      #STDOUT.puts "DocSize: L(#{@rect.getLeft()}) R(#{@rect.getRight()}) T(#{@rect.getTop()}) B(#{@rect.getBottom()})"
    
    end
    
    def onStartPage(writer,document)
      
      page_number = writer.getPageNumber()

      norf = BaseFont.createFont(DEFAULT_FONT_NORMAL1,"Identity-H",true)
      boldf = BaseFont.createFont(DEFAULT_ONT_BOLD1,"Identity-H",true)
            
      ph = Phrase.new(@report_name,Font.new(boldf,DEFAULT_FONT_SIZE+2,1))
      ColumnText.showTextAligned(@cb,Element.ALIGN_CENTER,ph,@cb_center,@cb_top,0)       
      
      marg_logo = 0
      marg_logo = 73 if Aohs::WEB_CLOGO != false
      ph = Phrase.new(@report_title,Font.new(norf,DEFAULT_FONT_SIZE))
      ColumnText.showTextAligned(@cb,Element.ALIGN_LEFT,ph,@cb_left + marg_logo,@cb_top,0) 

      ph = Phrase.new("Page: #{page_number}",Font.new(norf,DEFAULT_FONT_SIZE))
      ColumnText.showTextAligned(@cb,Element.ALIGN_RIGHT,ph,@cb_right,@cb_top,0) 

      ph = Phrase.new("#{Time.new.strftime("%Y/%m/%d %H:%M:%S")}",Font.new(norf,DEFAULT_FONT_SIZE))
      ColumnText.showTextAligned(@cb,Element.ALIGN_RIGHT,ph,@cb_right,@cb_top - 15,0) 

      ph = Phrase.new(@report_description,Font.new(norf,DEFAULT_FONT_SIZE,1))
      ColumnText.showTextAligned(@cb,Element.ALIGN_CENTER,ph,@cb_center,@cb_top - 23,0) 
      
      if Aohs::WEB_CLOGO != false
        logo = Image.getInstance(REPORT_LOGO_FPATH)
        logo.setAbsolutePosition(0,0)
        tp = @cb.createTemplate(70,55);
        tp.addImage(logo);
        @cb.addTemplate(tp,@cb_left,@cb_top - 20);
      end
      ph, logo = nil, nil
       
      STDOUT.puts "StartPage:#{page_number}"
      
    end
    
    def onEndPage (writer,document) 
      
      page_number = writer.getPageNumber()
      
      STDOUT.puts "EndPage:#{page_number}"
           
    end
    
  end # end inner class
  
end