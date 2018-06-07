var _appSiteRedirection = {
  
  __urlExists: function(url, callback){
    $.ajax({
      type: 'HEAD',
      url: url,
      success: function(){
        callback(true);
      },
      error: function() {
        callback(false);
      }
    });
  },

  __redirectLoginPage: function()
  {
    var o = $("select#site_redirect_to");
    if(o.length > 0){
      o.on('change',function(){
        var oa = $("option:selected", o);
        if(oa.length > 0){
          _appSiteRedirection.__urlExists(oa.val(),function(result){
            if(result){
              window.location.href = oa.val();  
            } else {
              appl.noty.error("Sorry, your selection is not available.");
            }
          });
        }
      });
    }
  },
  
  init: function()
  {
    _appSiteRedirection.__redirectLoginPage();
  }
  
};