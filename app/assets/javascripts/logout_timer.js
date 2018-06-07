var logoutTimer = function(){
  return {
    start: function(){
      
      var timeLoop = 1000 * 60 * 1;
      var timeOut = 1000 * 60 * 1;
      var timer = null;
      var requireCheck = true;
      var lastPingTime = new Date();
      
      function checkPing() {
        if (requireCheck) {
          lastPingTime = new Date();
          jQuery.ajax(Routes.check_system_info_index_path(),{
            data: { c: gon.params.controller },
            success: function(data){
              if (data && data.login_required) {
                appl.redirectTo(Routes.logout_users_path());
              } else {
                timer = setTimeout(function(){ startTimer(); }, timeLoop);
              }
            },
            error: function(){
              timer = setTimeout(function(){ startTimer(); }, timeLoop);
            }
          });        
        } else {
          timer = setTimeout(function(){ startTimer(); }, timeLoop);
        }
      }
      
      function isTimeCheck() {
        if ((new Date() - lastPingTime) > timeOut) {
          return true;
        }
        return false;
      }
      
      function startTimer() {
        checkPing();
      }
      
      function disableLogoutTimer() {
        return (gon.params.controller == "devise/sessions");
      }
      
      if (!disableLogoutTimer()) {
        startTimer();
        $(window).on('focus',function(){
          /* check every 5 mins */
          requireCheck = true;
          timeLoop = 1000 * 60 * 1;
        });
        $(window).on('blur',function(){
          /* check after timeout+1*/
          requireCheck = true;
          timeLoop = 1000 * 60 * 100;
        });
      }
      
    } //start  
  }; //return
};