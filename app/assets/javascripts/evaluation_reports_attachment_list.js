var fnRp = {
  loadTable: function(){
    var params = fnEvaluationRp.getEvaluationFilters();
    appl.redirectTo(Routes.attachment_list_evaluation_reports_path(params));
  },
  downloadFile: function(){
    var params = fnEvaluationRp.getEvaluationFilters();
    appl.fileDownload(appl.mkUrl(Routes.attachment_list_evaluation_reports_path({format: 'xlsx'}), params));
  },
  renderTable: function(){
    var o = $("#block-attach-list table");
    fnRp.oTbl = o.DataTable(fn_reports.tblOptions);
    $(".btn-download-attch").off('click').on('click',function(){
      var o = $(this);
      appl.fileDownloadWithFormat(function(filetype){
        return Routes.download_evaluation_doc_attachments_path({ format: filetype }) + "?template_id=" + o.attr("data-template-id") + "&log_id=" + o.attr("data-log-id");
      },appl.cof.dialogFileType.evaluationAttachment);
    });
  },
  init: function(){
    $("select#document_template").on('change',function(){
      var o = $("option:selected",this);
      appl.redirectTo(Routes.attachment_list_evaluation_reports_path({ template_id: o.val() }));
    });
    fnRp.renderTable();
  }
};

jQuery(document).on('ready page:load',function(){ fnRp.init(); });
