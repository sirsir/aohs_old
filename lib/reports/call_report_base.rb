class CallReportBase < ReportBase

  include CustomQueryReport::AeonQuery
  
  def initial_report
    if timely_report?(@opts[:period_by])
      @period_type = @opts[:period_by].to_sym
      @sdate = @opts[:sdate]
      @edate = @opts[:edate]
      date_range_init
    end
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
  
  def inbound_stats_details
    unless defined? @ds_inb_list
      @ds_inb_list = CallStatistic.statistic_type_ranges(:count, :inbound, :duration_range)
    end
    return @ds_inb_list
  end
    
  def outbound_stats_details
    @ds_outb_list
    unless defined? @ds_outb_list
      @ds_outb_list = CallStatistic.statistic_type_ranges(:count, :outbound, :duration_range)
    end
    return @ds_outb_list
  end
    
  private
  
  def selected_columns
    scols = @opts[:columns] || []
    scols = scols.map { |cl| mapped_selected_columns(cl) }
    return scols
  end
  
  def selected_summary_columns
    scols = []
    selected_columns.each do |co|
      cl = {}
      cl[:name] = co[:name]
      cl[:display_name] = co[:display_name]
      cl[:select_prefix] = co[:select_prefix]
      cl[:unit] = co[:unit]
      scols << cl
      if co[:name] == :number_of_call and @opts[:show_average_call_per_day] == true
        # average call per day
        cl = {}
        cl[:name] = :avg_number_of_call_perday
        cl[:display_name] = "Avg. Number of Call/Day"
        cl[:select_prefix] = "ac"
        scols << cl
      end
    end
    return scols
  end
  
  def mapped_selected_columns(name)
    cl = {}
    case name.to_s.downcase.strip
    when "n_of_call"
      cl[:name] = :number_of_call
      cl[:display_name] = "Number Of Call"
      cl[:select_prefix] = "nc"
    when "total_duration"
      cl[:name] = :total_duration
      cl[:display_name] = "Total Duration"
      cl[:select_prefix] = "td"
      cl[:unit] = :duration
    when "max_duration"
      cl[:name] = :max_duration
      cl[:display_name] = "Max Duration"
      cl[:select_prefix] = "md"
      cl[:unit] = :duration
    when "avg_duration"
      cl[:name] = :avg_duration
      cl[:display_name] = "Avg. Duration"
      cl[:select_prefix] = "ad"
      cl[:unit] = :duration
    end
    return cl
  end
  
  # end class
end