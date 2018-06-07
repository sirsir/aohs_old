var fnAna = {
  
  getFilter: function()
  {
    var ft = {};
    ft.period_type = getVal($("#fl-period-type option:selected").val());
    ft.date_range = getVal($("#fl-date-range").val())
    ft.group_name = getVal($("#fl-group-name").val());
    ft.user_name = getVal($("#fl-user-name").val());
    ft.view_as = getVal($("#fl-show-type option:selected").val());
    return ft;
  },
  
  showData: function()
  {
    
    function showSummary(sm)
    {
      var ds_chart = [];
      var o = $("#tbl-category-summary table");
      o.html("");
      sm.forEach(function(d){
        o.append("<tr><td>" + d.name + "</td><td class=\"text-right\">" + d.value + "</td></tr>");
        ds_chart.push([d.name,d.value]);
      });
      
      var s_chart = c3.generate({
        bindto: "#gp-class-summary",
        data: {
          columns: ds_chart,
          type: 'bar'
        },
        axis: {
          x: {
            show: false,
            tick: { centered: false }
          },
          y: {
            min: 1
          }
        }
      });
    }
    
    function showTrend(hd,dt)
    {
      var dates = [];
      hd[0].forEach(function(h){
        dates.push(h.title);
      });
      
      var s_chart = c3.generate({
        bindto: "#gp-class-trend",
        data: {
          columns: dt
        },
        axis: {
          x: {
            type: 'category',
            categories: dates,
            tick: {
              centered: false,
              rotate: 75,
              multiline: false
            },
            height: 60
          },
          y: {
            min: 1
          }
        }
      });
    }
    
    var ft = fnAna.getFilter();
    var url = Routes.classification_analytics_path({ format: 'json' });
    jQuery.getJSON(url,ft,function(data){
      showSummary(data.summary);
      showTrend(data.header,data.data);
    });
  },
  
  init: function()
  {
    fn_reports.setDateRangePickerField();
    fn_reports.setAgentAutoCompleteField();
    fn_reports.setGroupAutoCompleteField();
    
    $("#btn-search").on('click',function(){
      fnAna.showData();  
    });
  }
}

jQuery(document).on('ready page:load',function(){ fnAna.init(); });