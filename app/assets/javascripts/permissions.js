var fnPermis = {
  updagePermssion: function(p){
    var o = $(p);
    var d = {
      checked: o.is(':checked')
    };
    jQuery.get(o.attr("data-url"),d,function(data){
      if (data == "updated") {
        //appl.noty.info("Permission has been updated.");
      }
    });
  }
};

function onUpdatePermission(p){
  fnPermis.updagePermssion(p);
}