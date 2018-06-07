var fnProfile = {
  init: function(){
    function initTab(){
      if(gon.params.target == "change_password"){
        $("#tab-authentication").trigger("click");
      }
    }
    
    initTab();
  }  
};

jQuery(document).on('ready page:load',function(){ fnProfile.init(); });