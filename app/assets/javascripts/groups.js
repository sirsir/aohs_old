var fnGroup = {
  
  initForm: function()
  {
    $("#group_group_leader_user_id").select2();
  },
  
  init: function()
  {
    if (gon.params.action == "new" || gon.params.action == "edit") {
      fnGroup.initForm();
    }
  }
  
}

jQuery(document).on('ready page:load',function(){ fnGroup.init(); });
