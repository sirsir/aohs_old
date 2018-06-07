require File.join(File.dirname(__FILE__),'report_base')
require File.join(File.dirname(__FILE__),'table_header')

class AnalyticsReportBase < ReportBase
  
  include CustomQueryReport::AeonQuery
  
  def init_report
    initial_report
  end
  
  def initial_report
    create_headers
  end
  
  def create_headers
    @th = TableHeader.new
    @headers = @th.headers
    @start_at_row = 0
    @styles = []
  end
  
  def add_header(cols, row_at, col_at)
    @th.add_header(cols, row_at, col_at)  
    @headers = @th.headers
  end

end