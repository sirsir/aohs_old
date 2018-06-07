var fnRp = {
  oTbl: null,
  
  loadTable: function(){
    var params = fn_reports.getCallFilter();
    var renderTable = function(data){
      var o = $("#call_report");
      var t = appl.getHtmlTemplate("#table_template");
      if (isNotNull(fnRp.oTbl)) {
        fnRp.oTbl.destroy();
      }
      o.html(t(data));
      var topts = {};
      jQuery.extend(topts,{ data: data.data, "order": [[ 0, "desc" ]] },fn_reports.tblOptions);
      fnRp.oTbl = o.DataTable(topts);
      $('tr > td > a').off('click').on('click',function(){
        var a = $(this);
        var rdata = fnRp.oTbl.row(a.closest('tr')).data();
        fn_reports.openCallListDialog(fn_reports.getCallHistFilter(a.attr("data-searchkey") + "|lbdate=" + rdata[0]));
      });
      appl.dialog.hideWaiting();
    };
    
    appl.dialog.showWaiting();
    jQuery.getJSON(Routes.call_overview_reports_path({ format: 'json' }),params,renderTable);
  },
  
  downloadFile: function(){
    var params = fn_reports.getCallFilter();
    appl.fileDownload(appl.mkUrl(Routes.call_overview_reports_path({ format: 'xlsx' }), params));
  },
};
