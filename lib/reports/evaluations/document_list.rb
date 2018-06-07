module EvaluationReport
  class DocumentList < EvaluationReportBase

    def initialize(template_id, opts={})
      @opts = opts
      @document = DocumentTemplate.where(id: template_id).first
      @opts[:report_name] = "#{@document.title}"
      initial_report
      initial_header
      
      log "parameters: #{@opts.inspect}"
    end
    
    def initial_header
      row_cnt = @headers.length
      cols = []
      @document.display_fields.each do |field|
        cols << new_element(field[:title], 1, 1)
      end
      add_header(cols,0,0)
    end
    
    def to_xlsx
      wb = Axlsx::Package.new
      ws = wb.workbook.add_worksheet(name: 'report')
      wt = ws.styles
      sty1 = wt.add_style(STYHDR_1)
      sty2 = wt.add_style(STYNMC_1)
      
      headers, spans = get_xlsx_headers
      headers.each_with_index do |row,i|
        ws.add_row row, style: sty1
      end
      spans.each do |cell|
        ws.merge_cells cell
      end
      
      data = get_data
      data.each do |row|
        ws.add_row row, style: sty2
      end
      
      @out_fpath = xlsx_fname(@opts[:report_name])
      wb.serialize(@out_fpath)

      return {
        path: @out_fpath
      }
    end
    
    def get_data
      @all_attachments = EvaluationDocAttachment.search(@opts[:conditions]).result.not_deleted.order(updated_at: :desc)     
      data = []
      @all_attachments.each_with_index do |r,i|
        d = []
        @document.display_fields.each do |field|
          d << r.mapped_fields_for_render[field[:name]]
        end
        data << d
      end
      return data
    end
    
    # end class
  end
end