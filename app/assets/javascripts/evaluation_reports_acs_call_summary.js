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
      var topts = fn_reports.tblOptions;
      jQuery.extend(topts,{
        "bSort": false
      });
      fnRp.oTbl = o.DataTable(jQuery.extend({ data: data.data }, topts));
      appl.dialog.hideWaiting();
    };
    appl.dialog.showWaiting();
    jQuery.getJSON(Routes.acs_call_summary_evaluation_reports_path({format: 'json'}),params,renderTable);
  },
  
  downloadFile: function(){
    var params = fnEvaluationRp.getEvaluationFilters();
    appl.fileDownload(appl.mkUrl(Routes.acs_call_summary_evaluation_reports_path({format: 'xlsx'}), params));
  },
};
