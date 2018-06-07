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
      try {
        o.html(t(data));
        if(data.data.length > 0){
          fnRp.oTbl = o.DataTable(jQuery.extend({ data: data.data, "order": [[ 2, "desc" ]] }, fn_reports.tblOptions));
        }
      } catch(e){}
      appl.dialog.hideWaiting();
    };
    appl.dialog.showWaiting();
    jQuery.getJSON(Routes.acs_evaluation_summary_evaluation_reports_path({format: 'json'}),params,renderTable);
  },
  
  downloadFile: function(){
    var params = fnEvaluationRp.getEvaluationFilters();
    appl.fileDownload(appl.mkUrl(Routes.acs_evaluation_summary_evaluation_reports_path({format: 'xlsx'}), params));
  },
};
