var fnFaq = {
  init: function(){
    function resizeIframe(){
      var oi = $("iframe.if-autoresize");
      if(oi.length > 0){
        var w = $(window).height() * 2.5;
        oi.each(function(){
          var o = $(this);
          o.height(w);
        });  
      }
    }
    resizeIframe();
  }
};

jQuery(document).on('ready page:load',function(){ fnFaq.init(); });
