//= require 'jquery.sparkline'

var fnIndex = {
  widgetCallCount: function(){
    function render(){
      jQuery.getJSON(Routes.call_activity_maintenances_path(),function(data){
        $('#fd-agent-count').html(data.a.count);
        $('#fd-exts-count').html(data.a.exts_count);
        $('#sparkline-agents').sparkline(data.a.list, { type: 'bar', barColor: 'white', height: '25' });
        $('#fd-inb-count').html(data.i.count);
        $('#fd-inb-duration').html(data.i.duration);
        $('#sparkline-inbound').sparkline(data.i.list, { type: 'bar', barColor: 'white', height: '25' });
        $('#fd-outb-count').html(data.o.count);
        $('#fd-outb-duration').html(data.o.duration);
        $('#sparkline-outbound').sparkline(data.o.list, { type: 'bar', barColor: 'white', height: '25' });
      }); 
    }
    render();
  },
  
  init: function(){
    fnIndex.widgetCallCount();
  }
};

jQuery(document).on('ready page:load',function(){ fnIndex.init(); });