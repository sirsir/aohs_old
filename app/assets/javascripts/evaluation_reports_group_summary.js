var fnRp = {
  oTbl: null,
  
  loadTable: function(){
    var params = fnEvaluationRp.getEvaluationFilters();
    var renderTable = function(data){
      var o = $("#evaluation_report");
      var t = appl.getHtmlTemplate("#table_template");
      if (fnRp.oTbl !== null) {
        fnRp.oTbl.destroy();
      }
      o.html(t(data));
      fnRp.oTbl = o.DataTable(jQuery.extend({ data: data.data }, fn_reports.tblOptions));
      appl.dialog.hideWaiting();
    };
    appl.dialog.showWaiting();
    jQuery.getJSON(Routes.group_summary_evaluation_reports_path({format: 'json'}),params,renderTable);
  },
  
  downloadFile: function(){
    var params = fnEvaluationRp.getEvaluationFilters();
    appl.fileDownload(appl.mkUrl(Routes.group_summary_evaluation_reports_path({format: 'xlsx'}), params));
  },
};
