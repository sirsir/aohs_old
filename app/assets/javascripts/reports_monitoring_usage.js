var fnCallview = {
  showInfo: function()
  {
    function chartOpts(d)
    {
      var opts = {
        bindto: "#callview-" + d.user_id,
        size: {
          height: 30
        },
        data: {
            x: 'x',
            columns: [ d.ddate, d.dcount ],
            type: 'bar'
        },
        legend: {
          show: false
        },
        point: {
          show: false
        },
        axis: {
          y: {
            show: false
          },
          x: {
            show: false,
            type: 'timeseries',
            tick: {
              format: '%Y-%m-%d'
            }
          }
        }
      }
      return opts;
    }
    
    var url = Routes.monitoring_usage_reports_path({format: 'json'});
    var dgp = function(data)
    {
      var template = appl.getHtmlTemplate("#call-view-template");
      $("#call_view_list").html(template(data));
      var l = data.length;
      for(var i=0; i<l; i++){
        var chart = c3.generate(chartOpts(data[i]));
      }
      data = [];
    }
    jQuery.getJSON(url,{},dgp);
  },
  
  init: function()
  {
    this.showInfo();
  }
}

jQuery(document).on('ready page:load',function(){ fnCallview.init(); });