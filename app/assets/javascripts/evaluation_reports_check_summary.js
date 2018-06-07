var fnRp = {
  oTbl: null,
  
  //openDetailLog: function(row){
  //  var params = fnEvaluationRp.getEvaluationFilters();
  //  params.qa_agent_name = row[0];
  //  bootbox.dialog({
  //    title: 'Detail',
  //    size: 'large',
  //    animate: false,
  //    message: jQuery('<div/>',{ class: 'panel' }).append(jQuery('<table/>', { id: 'tbl-detail', class: 'table table-striped table-bordered table-hover table-default-all'})),
  //    closeButton: true
  //  }).init(function(){
  //    var dia = $('table#tbl-detail', $(this));
  //    jQuery.getJSON(Routes.check_detail_evaluation_reports_path(),params,function(data){
  //      var t = appl.getHtmlTemplate("#table_template");
  //      dia.html(t(data));
  //      var tb = dia.DataTable(jQuery.extend({ data: data.data }, fn_reports.tblOptions));
  //      setTimeout(function(){
  //        tb.columns.adjust();
  //      },1000);
  //    });
  //  });
  //},
  
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
      fnRp.oTbl = o.DataTable(jQuery.extend({
        data: data.data
      }, topts));
      appl.dialog.hideWaiting();
      //$('#evaluation_report tbody').on('click', 'td', function(){
      //  var data = fnRp.oTbl.cell(this).index();
      //  if((data.column !== undefined) && (data.column == oolLength)){
      //    var row = fnRp.oTbl.row(data.row).data();
      //    fnRp.openDetailLog(row);
      //  }
      //});
    };
    appl.dialog.showWaiting();
    jQuery.getJSON(Routes.check_summary_evaluation_reports_path({format: 'json'}),params,renderTable);
  },
  
  downloadFile: function(){
    var params = fnEvaluationRp.getEvaluationFilters();
    appl.fileDownload(appl.mkUrl(Routes.check_summary_evaluation_reports_path({format: 'xlsx'}), params));
  },
};
