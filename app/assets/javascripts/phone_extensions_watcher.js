var fnWatcher = {
  
  init: function()
  {
    $("#btn-search-log").on('click',function(){
      var url = Routes.watcher_extensions_path() + "?log_date=" + $("input[name=log_date]").val(); 
      appl.redirectTo(url);  
    });
  }
  
}
jQuery(document).on('ready page:load',function(){ fnWatcher.init(); });