//= require 'jquery.jsonview'

var fnShow = {
  init: function(){
    $("td.json-view").each(function(){
      var o = $(this);
      $(this).JSONView(jQuery.parseJSON(o.text()));
    });
  }
}

jQuery(document).on('ready page:load',function(){ fnShow.init(); });