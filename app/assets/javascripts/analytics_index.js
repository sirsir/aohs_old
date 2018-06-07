var anaIndexFn = {
  filter: {
    category_id: 0  
  },
  
  getCurrentDateRange: function()
  {
    return {
      fr_d: $("input[name=calendar_fr_d]").val(),
      to_d: $("input[name=calendar_to_d]").val(),
      type: $("input[name=calendar_view_type]").val(),
      category_id: anaIndexFn.filter.category_id
    };
  },
  
  loadCallClass: function(){
    var url = appl.mkUrl(Routes.dasb_call_class_analytics_path(),anaIndexFn.getCurrentDateRange());
    jQuery.getJSON(url,function(data){
      var html = appl.getHtmlTemplate("#callclass-template");
      $("#dashb-call-class").html("");
      var i = 0;
      data.types.forEach(function(y){
        $("#dashb-call-class").append("<div=\"col-sm-12\"><h4>" + y + "</h4></div><div id=\"cate" + i + "\"class=\"row cate-sep\"></div>");
        data.result.forEach(function(x){
          if (y==x.category_type) {
            $("#dashb-call-class #cate" + i).append(html(x));
            $("#callclass-" + x.id + " .sparklines").sparkline(x.list, { type:'bar', barColor:'#1C86EE' });
            if (x.id == anaIndexFn.filter.category_id) {
              $("#callclass-" + x.id).addClass("selected-cate");
            }
            //$("#callclass-" + x.id)
            $("a.btn-callclass-select").off('click').on('click',function(){
              var cate_id = $(this).attr("data-category-id");
              $("#dashb-call-class div").removeClass("selected-cate");
              $(this).addClass("selected-cate");
              anaIndexFn.filter.category_id = parseInt(cate_id);
              anaIndexFn.loadCallClass();
            });
          }
        });
        i++;
      });
      
      var p = $("#box-top-callclass");
      var html2 = appl.getHtmlTemplate("#callclass-pg-template");
      p.html("");
      data.tops.forEach(function(x){
        p.append(html2(x));
      });
      
      $(".btn-find-callcate").off('click').on('click',function(){
        var o = $(this);
        var t = anaIndexFn.getCurrentDateRange();
        window.open(Routes.call_histories_path()+"?fr_d=" + t.fr_d + "&to_d=" + t.to_d + "&class_id=" + o.attr("data-category-id"));
      });

    });
  },
  
  loadWordCloud: function(){
    
    function getFilter(){
      var d = anaIndexFn.getCurrentDateRange();
      return { date_range: [d.fr_d, d.to_d].join(" - "), top_view: 5 };
    }
    
    function renderTopWords(data){
      var htm = appl.getHtmlTemplate("#keywords-pg-template");
      $("#box-top-keywords").html(htm(data));
    }
    
    jQuery.getJSON(Routes.word_cloud_analytics_path({ format: 'json'}), getFilter(), function(data){
      renderTopWords(data.top);
    });
  },
  
  init: function(){
    anaIndexFn.loadCallClass();
    anaIndexFn.loadWordCloud();
  }
};

jQuery(document).on('ready page:load',function(){
  anaIndexFn.init();
});