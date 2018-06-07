//= require datatable
//= require reports

var fnEvaluationRp = {
  getEvaluationFilters: function(){
    var dsFilters = {};
    /* view */
    if($("#fl-period-view").length > 0){
      dsFilters.period_by = $("#fl-period-view option:selected").val();
    }
    /* form */
    if($("#fl-evaluation-form").length > 0){
      if($("#fl-evaluation-form option").length > 0){
        /*select*/
        dsFilters.form_name = getVal($("#fl-evaluation-form option:selected").val());
      } else {
        dsFilters.form_name = getVal($("#fl-evaluation-form").val());
      }
    }
    /* col by */
    if($("#fl-col-by").length > 0){
      dsFilters.column_by = getVal($("#fl-col-by").val());
    }
    /* col by */
    if($("#fl-row-by").length > 0){
      dsFilters.row_by = getVal($("#fl-row-by").val());
    }
    /* calc */
    if($("#fl-calc").length > 0){
      dsFilters.calc = getVal($("#fl-calc").val());
    }
    /* date range */
    if($("#fl-date-range").length > 0){
      dsFilters.date_range = getVal($("#fl-date-range").val());
    }
    /* agent name */
    if($("#fl-user-name").length > 0){
      dsFilters.agent_name = getVal($("#fl-user-name").val());
    }
    if($("#fl-evaluator-id").length > 0){
      dsFilters.agent_id = getVal($("#fl-evaluator-id option:selected").val());
    }
    /* group name */
    if($("#fl-group-name").length > 0){
      dsFilters.group_name = getVal($("#fl-group-name").val());
    }
    /* template id */
    if($("select#document_template").length > 0){
      var o = $("select#document_template option:selected");
      dsFilters.template_id = getVal(o.val());
    }
    if($("select#call_type").length > 0){
      var d = $("select#call_type option:selected");
      dsFilters.call_type = getVal(d.val());
    }
    return Object.remove(dsFilters,function(ele){
      return (ele === null || ele.length <= 0);  
    });
  },
  
  adjustView: function(){
    if(fnRp !== undefined && fnRp.oTbl !== undefined){
      if(fnRp.oTbl !== null){
        fnRp.oTbl.columns.adjust();
      }
    }
  },
  
  init: function(){
    function setButtons(){
      $("button#btn-refresh").off('click').on('click', function(){ fnRp.loadTable(); });
      $("button#btn-download-xlsx").off('click').on('click', function() { fnRp.downloadFile(); });
    }
    function setFields(){
      fn_reports.setAgentAutoCompleteField();
      fn_reports.setDateRangePickerField();
      fn_reports.setEvaluationFormAutoField();
      fn_reports.setGroupAutoCompleteField();
    }
    setButtons();
    setFields();
    $(window).on('resize',fnEvaluationRp.adjustView);
  }
};

jQuery(document).on('ready page:load',function(){ fnEvaluationRp.init(); });