var fnIndex = {
  init: function(){
    function setButtons(){
      $("input[name=enable_task]").on('change',function(){
        var o = $(this);
        jQuery.getJSON(Routes.change_task_status_evaluation_task_path(o.attr("data-task-id")),{
          enable: o.prop('checked')
        },function(){
          appl.noty.info("Task has been updated.");
        });
      });
    }
    setButtons();
  }
};

jQuery(document).on('ready page:load',function(){ fnIndex.init(); });