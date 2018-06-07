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
      console.log(data.footer);
      var topts = fn_reports.getDataTableOptions({ data: data.data, footer: data.footer, "order": [[ 2, "desc" ]] });
      fnRp.oTbl = o.DataTable(topts);
      appl.dialog.hideWaiting();
    };
    appl.dialog.showWaiting();
    jQuery.getJSON(Routes.evaluator_call_summary_evaluation_reports_path({format: 'json'}),params,renderTable);
  },
  
  downloadFile: function(){
    var params = fnEvaluationRp.getEvaluationFilters();
    appl.fileDownload(appl.mkUrl(Routes.evaluator_call_summary_evaluation_reports_path({format: 'xlsx'}), params));
  },
};
