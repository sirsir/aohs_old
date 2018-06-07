var fnEdit = {
  
  downloadPreview: function(){
    appl.fileDownload(Routes.download_preview_document_template_path(gon.params.id));
  },
  
  init: function(){
    $("#btn-dl-preview").on('click',function(){
      fnEdit.downloadPreview();
    });
    $("#btn-upload").on('click',function(){
      $("#document_template_file_data").closest('div.form-group').css('display','block');
      $(this).addClass('btn-hidden');
    });
    if(gon.params.id !== undefined){
      $("#document_template_file_data").closest('div.form-group').css('display','none');
    }
  }
};

jQuery(document).on('ready page:load',function(){fnEdit.init();});