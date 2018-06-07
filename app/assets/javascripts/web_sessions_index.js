var fnWss = {
  
  init: function()
  {
    $(".btn-unlock").on('click',function(){
      $.getJSON(Routes.unlock_user_path($(this).attr("data-user-id")),{},function(data){
        if (data.unlock == "success") {
          appl.noty.info("Already unlock this account.");
          window.location.reload();
        }
      });
    });
  }

}
jQuery(document).on('ready page:load',function(){ fnWss.init(); });