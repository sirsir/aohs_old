var fnAtchShow = {
  
  reloadDocs: function()
  {
    parent.fnEvaluationEdit.initDocTemplate();
    parent.bootbox.hideAll();
  },
  
  init: function()
  {
    $("#btn-close").on('click',function(){
      fnAtchShow.reloadDocs();
    });
    
    $("#btn-edit").on('click',function(){
      appl.redirectTo(Routes.edit_evaluation_plan_document_template_path(gon.params.evaluation_plan_id, gon.params.id));
    });
    
    $("#btn-delete").on('click',function(){
      var fndel = function(){
        jQuery.get(Routes.remove_temp_evaluation_plan_document_template_path(gon.params.evaluation_plan_id, gon.params.id),function(data){
          fnAtchShow.reloadDocs();
        });
      }
      appl.dialog.deleteConfirm2(fndel);
    });
  }
}

jQuery(document).on('ready page:load',function(){ fnAtchShow.init(); });