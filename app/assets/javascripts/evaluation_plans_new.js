var fnPlanNew = {
  init: function()
  {
    $("form[name=evaluation_plan]").on('ajax:success',function(e, data, status, xhr){
      var resp = jQuery.parseJSON(xhr.responseText);
      if (isPresent(resp.errors)) {
        var f = $("form[name=evaluation_plan]");
        for(var key in resp.errors){
          var o = $("#" + key);
          o.parent().next().remove();
          var m = $("<span>",{ class: 'help-block', text: resp.errors[key].join(",") });
          var x = $("<div>",{ class: 'col-sm-offset-2 col-sm-10', text: "" }).append(m);
          o.closest(".form-group").addClass('has-error').append(x);
        }
      } else {
        appl.redirectTo(Routes.edit_evaluation_plan_path({ id: resp.id }));
      }
    });
  }  
}

jQuery(document).on('ready page:load',function(){ fnPlanNew.init(); });