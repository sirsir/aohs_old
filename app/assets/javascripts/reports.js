//= require 'charts'
//= require 'datatable'

var fn_reports = {
  
  dsHeaderInfo: [],
  
  getCallHistFilter: function(add_params){
    var params = fn_reports.getCallFilter();
    if(add_params !== undefined){
      add_params.split("|").forEach(function(p){
        var sp = p.split("=");
        params[sp[0]] = sp[1];
      });
    }
    /* change name and value */
    if(params.date_range !== undefined){
      if(params.lbdate !== undefined){
        var d2 = params.lbdate.split(" - ");
        if(params.period_by == 'daily'){
          params.d = moment(d2[0]).format('YYYY-MM-DD');
        } else if(params.period_by == 'weekly'){
          params.w = moment(d2[0]).get('W')+1;
          params.y = moment(d2[0]).get('y');
        }else if(params.period_by == 'monthly'){
          params.m = moment(d2[0]).get('m')+1;
          params.y = moment(d2[0]).get('y');
        }
      } else {
        var d = params.date_range.split(" - ");
        params.fr_d = d[0];
        params.to_d = d[1];
      }
    }
    if(params.dur_fr !== undefined){
      params.dur_fr = appl.secToTime(params.dur_fr); 
    }
    if(params.dur_to !== undefined){
      params.dur_to = appl.secToTime(params.dur_to);
    }
    if(params.cd !== undefined){
      params.dir = params.cd;
    }
    return params;
  },
  
  getCallFilter: function(){
    var dsFilters = {};
    /* view */
    if($("#fl-period-view").length > 0){
      dsFilters.period_by = $("#fl-period-view option:selected").val();
    }
    /* col by */
    if($("#fl-col-by").length > 0){
      dsFilters.column_by = getVal($("#fl-col-by").val());
    }
    /* row by */
    if($("#fl-row-by").length > 0){
      dsFilters.row_by = $("#fl-row-by").val();
    }
    /* date range */
    if($("#fl-date-range").length > 0){
      dsFilters.date_range = getVal($("#fl-date-range").val());
    }
    /* agent name */
    if($("#fl-user-name").length > 0){
      dsFilters.agent_name = getVal($("#fl-user-name").val());
    }    
    /* group name */
    if($("#fl-group-name").length > 0){
      dsFilters.group_name = getVal($("#fl-group-name").val());
    }
    /* limit, top */
    if($("#fl-limit").length > 0){
      dsFilters.limit = $("#fl-limit option:selected").val();
    }
    /* phone type */
    if($("#fl-phone-type").length > 0){
      dsFilters.phone_type = $("#fl-phone-type option:selected").val();
    }
    /* cd */
    if($("#fl-call-direction").length > 0){
      dsFilters.call_direction = $("#fl-call-direction option:selected").val();
    }
    /* tag */
    if($("#fl-tag-call").length > 0){
      dsFilters.tag_id = $("#fl-tag-call option:selected").val();
    }
    /* section */
    if($("#fl-atlsection-name").length > 0){
      dsFilters.section_name = $("#fl-atlsection-name").val();
    }
    /* type of report */
    if($("#output_type").length > 0){
      dsFilters.output_type = $("#output_type").val();
    }
    /* word */
    if($("#fl-keyword").length > 0){
      dsFilters.keyword = getVal($("#fl-keyword").val());
    }
    /* duration format */
    if($("#fl-duration-fmt").length > 0){
      dsFilters.duration_fmt = $("#fl-duration-fmt option:selected").val();
    }
    /* cols */
    if($("input[name=\"fl-columns[]\"]").length > 0){
      dsFilters.scols = [];
      $("input[name=\"fl-columns[]\"]").each(function(){
        var o = $(this);
        if(o.prop('checked')){
          dsFilters.scols.push(o.val());  
        }
      });
      if(dsFilters.scols.length<=0){
        appl.noty.error("Please choose at lease one column to show in the report.");
      }
    }
    return Object.remove(dsFilters,function(ele){
      return (ele === null || ele.length <= 0);  
    });
  },
  
  
  col_params: [],
  
  defaultDataTableOption: function(){
    /* A set of default option for datatable */
    
    return {
      "lengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
      "scrollX": true,
      "paging": true,
      "searching": false,
      "info": false,
      "dom": 'tlirp',
      "preDrawCallback": function(settings) {
        fn_reports.dsHeaderInfo = [];
        settings.aoHeader.at(-1).forEach(function(col){
          var $cell = $(col.cell);
          fn_reports.dsHeaderInfo.push({ text: $cell.text(), searchkey: $cell.attr('data-searchkey'), clickable: $cell.attr('data-clickable') });  
        });
      },
      "fnRowCallback": function(nRow,aData,iDisplayIndex,iDisplayIndexFull){
        for (var i in aData){
          var v = aData[i];
          var h = fn_reports.dsHeaderInfo[i];
          var c = $('td:eq('+i+')', nRow);
          if (isNumeric(v) || isTimeString(v)){
            c.addClass("text-right");
            if((isDefined(h) && h.clickable == "true")) {
              v = jQuery('<a/>',{ href: "#", text: v, "data-searchkey": h.searchkey });
            }
          }
          c.html(v);
        }
      }
    };
  },
  
  getDataTableOptions: function(opts){
    /* To generate options for datatable */
    
    var xopts = opts || {};
    var retOpts = fn_reports.defaultDataTableOption();
    
    /* merge with passed options */
    jQuery.extend(retOpts,xopts);
    
    /* footer */
    if(isDefined(xopts.footer)){
      /* create footer if avaliable data using callback */
      if(isDefined(xopts.footer.data)){
        retOpts["footerCallback"] = function (row, data, start, end, display){
          var api = this.api();
          if(data.length > 0){
            for(var i=0; i<xopts.footer.data.length; i++){
              var cell = $(api.column(i).footer());
              cell.html(xopts.footer.data[i]);
              if(isNumeric(xopts.footer.data[i]) || isTimeString(xopts.footer.data[i])){
                cell.addClass('text-right');
              }
            }
          }
        }; /* end */
      } else {
        console.log("Undefined footer.data");
      }
    }

    return retOpts;
  },
  
  tblOptions: {
    "lengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
    "scrollX": true,
    "paging": true,
    "searching": false,
    "info": false,
    "dom": 'tlirp',
    "preDrawCallback": function( settings ) {
      fn_reports.dsHeaderInfo = [];
      settings.aoHeader.at(-1).forEach(function(col){
        var $cell = $(col.cell);
        fn_reports.dsHeaderInfo.push({ text: $cell.text(), searchkey: $cell.attr('data-searchkey'), clickable: $cell.attr('data-clickable') });  
      });
    },
    "fnRowCallback": function(nRow,aData,iDisplayIndex,iDisplayIndexFull){
      for (var i in aData){
        var v = aData[i];
        var h = fn_reports.dsHeaderInfo[i];
        var c = $('td:eq('+i+')', nRow);
        if (jQuery.isNumeric(v) || isTimeString(v)){
          c.addClass("text-right");
          if((h.clickable == "true")) {
            v = jQuery('<a/>',{ href: "#", text: v, "data-searchkey": h.searchkey });
          }
        }
        c.html(v);
      }
    }
  },
  
  openCallListDialog: function(params){
    var o = $("#dialog-call-hist");
    o.height(window.height);
    jQuery.extend(params,{ spnl: 'no', layout: 'blank' });
    var f = $('iframe',o);
    f.removeAttr("src");
    f.height(o.height());
    f.attr("src",Routes.call_histories_path(params));
    o.modal();
    $("#btn-close-call-dialog",o).off('click').on('click',function(){
      o.modal('hide');  
    });
    $(window).resize(function(){
       var o = $("#dialog-call-hist");
       $('iframe',o).height(o.height());
    });
  },
  
  setEvaluationFormAutoField: function(f_id){
    var fdname = f_id || "fl-evaluation-form";
    $("#" + fdname).select2({
      width: 160,
      placeholder: "",
      allowClear: true,
      ajax: {
        url: Routes.list_evaluation_plans_path(),
        dataType: 'json',
        cache: true,
        data: function(params){
          return { q: params.term };
        },
        processResults: function(data, page) {
          return { results: data };
        }
      }
    });
  },
  
  setAgentAutoCompleteField: function(f_id)
  {
    var fdname = f_id || "fl-user-name";
    
    var options = {
      url: function(phrase) {
        return Routes.list_users_path() + "?q=" + phrase;
      },
      
      getValue: function(element) {
        return element.name;
      },
      
      ajaxSettings: {
        dataType: "json",
        method: "GET",
        data: {
          dataType: "json"
        }
      },
      
      preparePostData: function(data) {
        data.phrase = $("#" + fdname).val();
        return data;
      },
      
      requestDelay: 300
    };
    
    $("#" + fdname).easyAutocomplete(options);    
  },

  setGroupAutoCompleteField: function(f_id)
  {
    var fdname = f_id || "fl-group-name";
    
    var options = {
      url: function(phrase) {
        return Routes.list_groups_path() + "?q=" + phrase;
      },
      
      getValue: function(element) {
        return element.name;
      },
      
      ajaxSettings: {
        dataType: "json",
        method: "GET",
        data: {
          dataType: "json"
        }
      },
      
      preparePostData: function(data) {
        data.phrase = $("#" + fdname).val();
        return data;
      },
      
      requestDelay: 300
    };
    
    $("#" + fdname).easyAutocomplete(options);    
  },
  
  setSectionAutoCompleteField: function(f_id)
  {
    var fdname = f_id || "fl-atlsection-name";
    
    var options = {
      url: function(phrase) {
        return Routes.list_groups_path() + "?t=atl-section&q=" + phrase;
      },
      
      getValue: function(element) {
        return element.name;
      },
      
      ajaxSettings: {
        dataType: "json",
        method: "GET",
        data: {
          dataType: "json"
        }
      },
      
      preparePostData: function(data) {
        data.phrase = $("#" + fdname).val();
        return data;
      },
      
      requestDelay: 300
    };
    
    $("#" + fdname).easyAutocomplete(options);    
  },
  
  setDateRangePickerField: function(f_id)
  {
    var fdname = f_id || "fl-date-range";

    var defaultDate = function(){
      function mapDate(t){
        var d = t.split(" - ");
        return { startDate: d[0], endDate: d[1] };
      }
      var o = $("#" + fdname);
      if((o.length > 0) && (o.val().length > 0)){
        return mapDate(o.val());
      } else if((o.length > 0) && o.attr("data-default-daterange") !== undefined && o.attr("data-default-daterange").length > 0){
        return mapDate(o.attr("data-default-daterange"));
      } else {
        var sd = moment().startOf('day').format(appl.cof.moment.fmt_d);
        var td = moment().endOf('day').format(appl.cof.moment.fmt_d);
        return mapDate(sd + " - " + td);           
      }
    };
    
    var options = {
      locale: {
        format: appl.cof.moment.fmt_d,
      },
      ranges:{
        'Today': [moment().startOf('day'), moment().endOf('day')],
        'Yesterday': [moment().startOf('day').subtract('days', 1), moment().endOf('day').subtract('days', 1)],
        'Last 7 Days': [moment().startOf('day').subtract('days', 6), moment().endOf('day')],
        'Last 30 Days': [moment().startOf('day').subtract('days', 29), moment().endOf('day')],
        'This Week': [moment().startOf('week').startOf('day'), moment().endOf('day')],
        'This Month': [moment().startOf('day').startOf('month'), moment().endOf('day').endOf('month')],
        'Last Month': [moment().startOf('day').subtract('month', 1).startOf('month'), moment().endOf('day').subtract('month', 1).endOf('month')]
      },
      startDate: defaultDate().startDate,
      endDate: defaultDate().endDate,
      timePicker: false,
      minDate: moment().startOf('day').subtract('month',12),
      maxDate: moment().endOf('day'),
      dateLimit: {
        days: 150
      }
    };
    
    $("#" + fdname).daterangepicker(options,function(){
      // nothing
    });
  },
  
  setTagAutoCompleteField: function(f_id)
  {
    var fdname = f_id || "fl-tag-call";
    
    var options = {
      
      url: function(phrase) {
        return Routes.autocomplete_tags_path() + "?q=" + phrase;
      },
      
      getValue: function(element) {
        return element.name;
      },
      
      ajaxSettings: {
        dataType: "json",
        method: "GET",
        data: {
          dataType: "json"
        }
      },
      
      preparePostData: function(data) {
        data.phrase = $("#" + fdname).val();
        return data;
      },
      
      requestDelay: 300
    };
    
    $("#" + fdname).easyAutocomplete(options);    
  },
  
  setGroupSelect: function(){
    appl.autocomplete.groupsSelect("#fl-group",{ width: '120px' });
  },

  adjustView: function(){
    if(isPresent(fnRp) && isPresent(fnRp.oTbl)){
      if(isNotNull(fnRp.oTbl)){
        fnRp.oTbl.columns.adjust();
      }
    }
  },
  
  callReportInit: function(){
    fn_reports.setAgentAutoCompleteField();
    fn_reports.setDateRangePickerField();
    fn_reports.setEvaluationFormAutoField();
    fn_reports.setGroupAutoCompleteField();
    fn_reports.setSectionAutoCompleteField();
    
    var bRef = $("button#btn-refresh"); 
    if(isFoundElement(bRef)){
      bRef.off('click').on('click', function(){
        fnRp.loadTable();
      });
    }
    
    var bDlf = $("button#btn-download-xlsx");
    if(isFoundElement(bDlf)){
      bDlf.off('click').on('click', function() {
        fnRp.downloadFile();
      });
    }
    
    $(window).on('resize',fn_reports.adjustView);
  },
  
  /* left side menu */
  
  _toggleLeftTimeout: null,
  toggleLeftSideMenu: function(){
    var o = $("div#block-left-side-menu");
    if(o.length > 0){
      if(gon.params.action !== "index"){
        o.off('mouseover').on('mouseover',function(){
          if(fn_reports._toggleLeftTimeout !== null){
            clearTimeout(fn_reports._toggleLeftTimeout);
          }
        })
        .off('click').on('click',function(){
          if(fn_reports._toggleLeftTimeout !== null){
            clearTimeout(fn_reports._toggleLeftTimeout);
          }
          o.addClass('slideInLeft').removeClass('hidden-panel');           

          o.off('mouseout').on('mouseout',function(){
            o.off('mouseout').on('mouseout',function(){
              fn_reports._toggleLeftTimeout = setTimeout(function(){
                o.removeClass('slideInLeft').addClass('hidden-panel');
              }, 800);
            })
          });
        })
      }else{
        o.addClass('slideInLeft').removeClass('hidden-panel');
      }
      $("span.list-header",o).on('click',function(){
        var p = $(this);
        if(p.attr("data-flag") == "hide"){
          p.attr("data-flag","shown");
          p.next().show();
        } else {
          p.attr("data-flag","hide");
          p.next().hide();
        }
        $("span.ico-showhide > i",p).toggleClass('fa-chevron-down fa-chevron-right');
      });
      if(gon.params.report_for !== undefined){
        $("span.list-header",o).trigger('click');
        $("span.list-header[data-menu-selector=\"" + gon.params.report_for + "\"]",o).trigger('click'); 
        if(gon.params.action !== "index"){
          o.addClass('hidden-panel');  
        }        
      }
      /* hide list */
      $(".block-left-side-inner ul.list-group > li").each(function(){
        var p = $(this);
        if($("ul.list-items > li",p).length <= 0){
          p.hide();
        }
      });
    }
  },
  
  _toggleButtonCheckbox: function(){
    $(".btn-group > button.btn-checkbox-toggle").off('click').on('click',function(){
      var o = $(this);
      if(($('input[type=checkbox]:checked',o.parent()).length <= 1) && (o.hasClass('btn-success'))){
        appl.noty.error("Please choose at least one column.");
      } else {
        o.toggleClass('btn-success');
        if(o.hasClass('btn-success')){
          $('input[type=checkbox]',o).prop('checked',true);
        } else {
          $('input[type=checkbox]',o).prop('checked',false);
        }
      }
    });
  },
  
  /* page init */
  
  init: function(){
    function isReportController(){
      return (gon.params.controller == "reports");
    }
    if(isReportController()){
      fn_reports.callReportInit();
    }
    fn_reports.toggleLeftSideMenu();
    fn_reports._toggleButtonCheckbox();
  }
};

jQuery(document).on('ready page:load',function(){ fn_reports.init(); });