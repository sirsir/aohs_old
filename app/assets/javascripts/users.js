var fn_user = {
  
  exportDialog: function(url){
    var expOpts = {
      title: "Export Users",
      message: appl.getHTML("#user-export-dialog"),
      buttons: {
        ok: {
          label: "Download",
          className: "btn-primary",
          callback: function(){
            var o = $(".bootbox select[name=file_type] option:selected");
            var ftype = o.val();
            appl.dialog.showWaiting();
            $.fileDownload(url + "&filetype=" + ftype,{
              successCallback: function(url){
                appl.dialog.hideWaiting();
              },
              failCallBack: function(url){
                appl.dialog.hideWaiting();
                appl.noty.error("Your download was unsuccessfully, please try again."); }
            });
          }
        },
        cancel: {
          label: "Cancel",
          className: "btn-default",
          callback: function(){ }
        }
      }
    };
    bootbox.dialog(expOpts);
  },
  init: function(){
    $(".btn-export-dialog").on("click",function(e){
      e.preventDefault();
      fn_user.exportDialog($('a',this).attr("href"));  
    });
  }
};

jQuery(document).on('ready page:load',function(){ fn_user.init(); });