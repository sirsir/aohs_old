var fnNew = {
  hindDialog: function(){
    parent.callEvaluate.hideAttachmentDialog(); 
  },
  
  downloadFile: function(){
    if(gon.params.dlfile == "yes"){
      var tid = $("input[name=document_template_id]").val();
      var lid = $("input[name=evaluation_log_id]").val();
      var url = Routes.download_evaluation_doc_attachments_path({ template_id: tid, log_id: lid, format: 'pdf' });
      appl.fileDownload(url);
    }
  },
  
  init: function(){
    $("#btn-delete").on('click',function(){
      var d_id = $(this).attr("data-id");
      jQuery.get(Routes.doc_delete_evaluation_doc_attachment_path({ id: d_id }),function(){
        fnNew.hindDialog();
      });
    });
    $("#btn-save-change-withdl").on('click',function(){
      $("input[name=\"dlfile\"]").val("yes");
    });
    setTimeout(function(){
      fnNew.downloadFile();
    },500);
  }
};

jQuery(document).on('ready page:load',function(){ fnNew.init(); });
