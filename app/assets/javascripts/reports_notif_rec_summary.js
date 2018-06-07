var fnRp = {
  oTbl: null,
  loadTable: function(){
    var params = fn_reports.getCallFilter();
    var renderTable = function(data){
      var o = $("#call_report");
      var t = appl.getHtmlTemplate("#table_template");
      if (fnRp.oTbl !== null){
        fnRp.oTbl.destroy();
      }
      o.html(t(data));
      var topts = fn_reports.getDataTableOptions({ data: data.data });
      fnRp.oTbl = o.DataTable(topts);
      appl.dialog.hideWaiting();
    };
    appl.dialog.showWaiting();
    jQuery.getJSON(Routes.notif_rec_summary_reports_path({format: 'json'}),params,renderTable);
  },
  downloadFile: function(){
    var params = fn_reports.getCallFilter();
    appl.fileDownload(appl.mkUrl(Routes.notif_rec_summary_reports_path({format: 'xlsx'}), params));
  },
};
