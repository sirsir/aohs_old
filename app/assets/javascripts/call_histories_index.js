//= require 'datatable'
//= require 'audioplayer'
//= require 'call_infos'

var vlTable;

var sh = {
  currentSearchKey: null,
  
  fromDate: moment().startOf('day').format(appl.cof.moment.fmt_dt),
  
  toDate: moment().endOf('day').format(appl.cof.moment.fmt_dt),
  
  gotKeys: false,
  
  currentPlayingRowNo: 0,
  
  errors: [],
  
  tblHtmlSrc: null,
  
  tblHtmlTem: null,
  
  paginate: {
    total_records: 0,
    total_pages: 0,
    current_page: 0,
    perpage: 0,
    first_row_no: 0,
    last_row_no: 0,
    order_col: "call_date",
    order_by: "desc"
  },
  
  summary_info: {
    total_inbound: 0,
    total_outbound: 0,
    total_duration: 0,
    total_records: 0
  },
  
  error: function(str) {
    sh.errors.push(str);
  },
  
  clearErrors: function() {
    sh.errors = [];
  },
  
  showErrors: function() {
    appl.noty.error(sh.errors[0]);
  },
  
  updateSearchKeys: function()
  {  
    function isCorrectInputDate(t){
      try {
        var dt = splitDateRange(t);
        if(!isDateTimeFT(t) || (!isDateTime(dt.fromDate) || !isDateTime(dt.toDate))){
          return false;
        }
      } catch(e) {
        return false;
      }
      return true;
    }
    
    function checkInputDate(t){
      if (isCorrectInputDate(t)) {
        var dt = splitDateRange(t);
        if (isDateTimeFrTo(dt.fromDate, dt.toDate)) {
          $("#cs-from_d").val(dt.fromDate);
          $("#cs-to_d").val(dt.toDate);            
        } else {
          sh.error("Start date must before End date"); 
        }
      } else {
        sh.error("Incorrect input date/time.");
      }
    }
    
    function checkPhoneNo(t){
      if (isLengthBetween(t,1,3)) {
        sh.error("Phone number is too short (at least 4 charectors).");
      }
    }

    function checkExtNo(t){
      if (isLengthBetween(t,1,3)) {
        sh.error("Incorrect extension format.");
      }
    }
    
    function checkDurationFormat(t1,t2){
      if (!isDurationFormat(t1) || !isDurationFormat(t2) || !isDurationFrTo(t1,t2)){
        sh.error("Invalid duration.");
      }
    }
    
    function checkRequiredText(t) {
      if(t.length > 0 && t.length < 3){
        sh.error("Phrase required at least 3 chars");
      }
    }
    
    function checkCorrectRangeInt(fr, to) {
      var fr2 = parseInt(fr) || 0;
      var to2 = parseInt(to) || 9999;
      if (to2 < fr2) {
        sh.error("Invalid range.");
      }
    }
    
    var fkeys = {};
    
    var lc = $("#cs-site-id option:selected");
    fkeys.site_id = getVal(lc.val());
    
    var op = $("#cs-period");
    fkeys.period = getVal(op.val());
    checkInputDate(fkeys.period);
    fkeys.date_from = getVal($("#cs-from_d").val());
    fkeys.date_to = getVal($("#cs-to_d").val());

    var tx = $("#cs-text");
    fkeys.text = getVal(tx.val());
    Cookies.set("keycallsearch-text",fkeys.text);
    checkRequiredText(fkeys.text);
    
    var rn = $("#cs-reasons");
    fkeys.reasons = getVal(rn.val());
    
    var oc = $("#cs-caller");
    fkeys.caller_no = getVal(oc.val());
    checkPhoneNo(fkeys.caller_no);
    
    var od = $("#cs-dialed");
    fkeys.dialed_no = getVal(od.val());
    checkPhoneNo(fkeys.dialed_no);
    
    var oe = $("#cs-ext");
    fkeys.extension = getVal(oe.val());
    checkExtNo(fkeys.extension);
    
    var odf = $("#cs-duration-from");
    fkeys.dur_fr = getVal(odf.val());
    var odt = $("#cs-duration-to");
    fkeys.dur_to = getVal(odt.val());
    checkDurationFormat(fkeys.dur_fr,fkeys.dur_to);
    
    var oro = $("#cs-repdial-opt");
    if(oro.length > 0){
      oro = $("#cs-repdial-opt option:selected");
      if(oro.length > 0 && oro.val() !== ""){
        fkeys.rdc_fr = parseInt(oro.attr("data-min-count"));
        fkeys.number_type = oro.attr("data-select-only");
      }
    } else {
      var orf = $("#cs-repdial-from");
      fkeys.rdc_fr = getVal(orf.val());
      var ort = $("#cs-repdial-to");
      fkeys.rdc_to = getVal(ort.val());
      checkCorrectRangeInt(fkeys.rdc_fr, fkeys.rdc_to);      
    }
    
    var oi = $("input[name=cs-direction]:checked");
    fkeys.direction = oi.val();
    
    var og = $("#cs-group");
    fkeys.group_name = getVal(og.val());
    
    var oa = $("#cs-agent");
    fkeys.agent_name = getVal(oa.val());
    
    var ot = $("#cs-tags");
    fkeys.call_tags = getVal(ot.val());
    
    var cu = $("#cs-customer");
    fkeys.customer_name = getVal(cu.val());
    
    var cid = $("#cs-call-id");
    fkeys.call_id = getVal(cid.val());
    
    var osc = $("#cs-atlsection");
    if(isFoundElement(osc)){
      fkeys.atlsection = getVal(osc.val());
    }
    
    fkeys.call_type = [];
    $("select[name=cs-flag]").each(function(){
      var ct = $("option:selected",this);
      if (ct.val().length > 0) {
        fkeys.call_type.push(getVal(ct.val()));
      }
    });
    
    /*qa*/
    if (gon.qa_enable) {
      fkeys.qa_enable = gon.qa_enable;
      
      var ef = $("#cs-form-id option:selected");
      fkeys.form_id = getVal(ef.val());
      
      var ex = $("#cs-ev-status option:selected");
      fkeys.ev_sts = getVal(ex.val());
      
      var et = $("#cs-evaluated-by option:selected");
      if(isFoundElement(et)){
        fkeys.evaluator_id = getVal(et.val());
      } else {
        if(isNotBlank(fkeys.ev_sts)){
          et = $("#cs-evaluated-by-only");
          fkeys.evaluator_id = et.val();
        }
      }
    }
    
    fkeys.only_fav = $("#btn-only-fav").hasClass("only-fav-call");
    
    fkeys.perpage = sh.paginate.perpage;
    fkeys.page = sh.paginate.current_page;
    fkeys.order_by = sh.paginate.order_col + " " + sh.paginate.order_by;
    sh.currentSearchKey = fkeys;
    
    if (!isAryEmpty(sh.errors)) {
      sh.gotKeys = false;
      sh.showErrors();
      sh.clearErrors();
      return false;
    }
    
    sh.gotKeys = true;
    return true;
  },
  findAndShow: function(){
  
    function startSearch(){
      var parms = {
        search: sh.currentSearchKey,
        paginate: sh.paginate,
        authenticity_token: window._frmTk,
        t: moment().format(appl.cof.moment.fmt_ut)
      };
      jQuery.post(Routes.list_call_histories_path(),parms,function(data){
        sh.loadToTable(data);
        appl.dialog.hideWaiting();
      }).error(function(){
        appl.dialog.hideWaiting();
        appl.noty.error("Something went wrong, please try again."); 
      });
    }
    
    if(sh.updateSearchKeys()){
      appl.dialog.showWaiting();
      startSearch();
    }
  },
  openCallDetailPage: function(id){
    var url = Routes.call_history_path({id: id});
    if (gon.qa_enable) {
      url = appl.mkUrl(url,{ qa: true, ef: sh.currentSearchKey.form_id });
    }
    var win = appl.openUrl(url, '_blank');
  },
  getCallDetailUrl: function(id){
    var url = Routes.call_history_path({id: id});
    if (gon.qa_enable) {
      url = appl.mkUrl(url,{ qa: true, ef: sh.currentSearchKey.form_id });
    }
    return url;
  },
  showCallDetail: function(id){
    
    function toggleMiniView(){
      if ($("#audioview").css("display") == "none") {
        $("#btn-toggle-audioview").trigger("click");
      }
    }
    
    function showCallInfo(){
      $.getJSON(Routes.info_voice_log_path({ id: id }),function(data){
        if (data.voice_url !== false) {
          var opts = {
            showWaveForm: false,
            autoPlay: true,
            id: id
          };
          ap.setAudioUrl(data.voice_url, opts);
          ap.setAttrs(id,null);
        } else {
          ap.reset();
          appl.dialog.hideWaiting();
          appl.noty.error("File is missing.");
        }
        callInfo.showAll(id);
      });
    }
    
    appl.dialog.showWaiting();
    toggleMiniView();
    showCallInfo();
  },
  changeOrder: function(){
    if (sh.paginate.order_by == "desc") {
      sh.paginate.order_by = "asc";
    } else {
      sh.paginate.order_by = "desc";
    }
  },
  loadToTable: function(data){
    
    function setSummaryInfo(sinf) {
      if (isPresent(sinf)) {
        sh.paginate.current_page = sinf.current_page;
        sh.paginate.total_pages = sinf.total_pages;
        sh.paginate.total_records = sinf.total_records;
        sh.paginate.first_row_no = sinf.first_row;
        sh.paginate.last_row_no = sinf.last_row;
        sh.summary_info.total_inbound = sinf.total_inbound;
        sh.summary_info.total_outbound = sinf.total_outbound;
        sh.summary_info.total_records = sinf.total_records;
        sh.summary_info.total_duration = sinf.total_duration_hms;
        sh.summary_info.total_in_duration = sinf.total_duration_in_hms;
        sh.summary_info.total_out_duration = sinf.total_duration_out_hms;
        pagi.updateInfo();
        sh.updateSummaryInfo();
      }
    }
    
    function resetView() {
      if (vlTable) {
        try {
          vlTable.destroy();
        } catch(e){}
      }
    }
    
    function appendDataToView(data){
      if(!isPresent(sh.tblHtmlSrc) || isNull(sh.tblHtmlSrc)){
        sh.tblHtmlSrc = appl.getHTML("#tbl-template");
        sh.tblHtmlTem = Handlebars.compile(sh.tblHtmlSrc);
      }
      $("#tbl-voicelogs").html(sh.tblHtmlTem(data));
      
      var h_scr = $('.dataTables_scrollHead').height();
      var h_tbl = $("#tbl-voicelogs").height() - h_scr - 32;
      var invisible_cols = [];
      
      var vopt  = appl.dtTable.options.voicelogs({ "scrollY": h_tbl });
      if(jQuery.trim($("#cs-text").val()).length <= 0){
        var ci = gon.display_table.findIndex(function(col){
          return col.variable_name == "found_sentence";
        });
        invisible_cols.push(ci+2);
      }
      
      // hide matched score
      var c_ms = gon.display_table.findIndex(function(col){
        return col.variable_name == "matched_score";
      });
      if(c_ms != null){
        invisible_cols.push(c_ms+2);
      }
      
      jQuery.extend(vopt,{ "columnDefs": [{ "targets": invisible_cols, "visible": false }]});
      
      vlTable = $('#tbl-voicelogs table').DataTable(vopt);

      $("span.btn_subcall").on("click",function(){
        var t_hide = "hide";
        var t_hideico = "hide-icon";
        var cx = $(this).closest('tr').attr("id");
        if($(appl.n_kls(cx)).hasClass(t_hide)){
          $(appl.n_kls(cx)).removeClass(t_hide);
          $(this).addClass(t_hideico);
        } else {
          $(appl.n_kls(cx)).addClass(t_hide);
          $(this).removeClass(t_hideico);
        }
      });
      
      $("button.btn-private-call-cb").off('click').on('click',function(){
        var opv = $(this);
        bootbox.confirm("Are you sure to change?", function(result){
          if(result){
            var id = null;
            try {
              id = parseInt(opv.attr("data-voice-id"));
            } catch(e){
              id = parseInt(opv.closest('tr').attr('data-voice-id'));
            }
            $('i',opv).toggleClass('fa-square-o fa-check');
            callInfo.checkPrivateCall(id,$('i',opv).hasClass('fa-check'));
          }
        });
      });
      init.setColumnOrder();
    }
    
    function bindRowEvents(){
      
      $("#tbl-voicelogs table thead").on('click','th',function(){
        var c = $(this);
        if (c.hasClass("sort_dt")) {
          var tx = $("#cs-text");
          if(getVal(tx.val()).length <= 0){
            sh.paginate.order_col = c.attr("data-col");
            sh.changeOrder();
            sh.findAndShow();            
          } else {
            appl.noty.error("Not allow you to sort when you search by text."); 
          }
        }
      });
      
      $("#tbl-voicelogs table tbody").on('click','tr',function(){
        var o = $(this);
        if (o.hasClass('selected')) {
          o.removeClass('selected');
        } else {
          vlTable.$('tr.selected').removeClass('selected');
          o.addClass('selected');
        }
      }).on('click','.button-show-detail',function(){
        var o = $(this).closest("tr");
        var curl = sh.getCallDetailUrl(o.attr("data-voice-id"));
        $(this).attr("href",curl);
        return true;
        //sh.openCallDetailPage(o.attr("data-voice-id"));
      }).on('click','.button-play-sound',function(){
        $("#tbl-voicelogs table tbody tr").removeClass("selected-show");
        var o = $(this).closest("tr");
        o.addClass("selected-show");
        sh.currentPlayingRowNo = parseInt(o.attr("data-row-no"));
        sh.showCallDetail(o.attr("data-voice-id"));
      }).on('click','.button-fav-call',function(){
        var o = $(this).closest("tr");
        $(this).toggleClass('favourited');
        sh.updateFavourite(o.attr("data-voice-id"),$(this).hasClass('favourited'));
      }).on('click','.btn_subcall',function(){
        $('i',$(this)).toggleClass('fa-minus-circle fa-plus-circle');
        var o = $(this).closest("tr");
        var no = o.attr("data-row-no");
        $('tr.child-row-no-'+no,$("#tbl-voicelogs table tbody")).toggleClass('hide-row');
      });
    }
    
    setSummaryInfo(data.summary_info);
    resetView();
    appendDataToView(data);
    bindRowEvents();
    resizeDisplayTable();
  },
  updateSummaryInfo: function(){
    $("#pg-total-in").text(appl.fmt.numberFmt(sh.summary_info.total_inbound));
    $("#pg-total-out").text(appl.fmt.numberFmt(sh.summary_info.total_outbound));
    $("#pg-total-call").text(appl.fmt.numberFmt(sh.summary_info.total_records));
    $("#pg-total-length").text("(" + sh.summary_info.total_duration + ")");
    $("#pg-total-in-length").text("(" + sh.summary_info.total_in_duration + ")");
    $("#pg-total-out-length").text("(" + sh.summary_info.total_out_duration + ")");
  },
  updateFavourite: function(id,fav){
    var url = Routes.fav_call_voice_log_path({ id: id });
    $.get(url,{ favourite: fav },function(data){});
  }
}

var init = {
  setTodayPicker: function(){
    var sd = moment().startOf('day').format(appl.cof.moment.fmt_dt);
    var td = moment().endOf('day').format(appl.cof.moment.fmt_dt);
    $("#cs-period").val(sd + " - " + td);
  },
  setDateTimePicker: function(){
    var options = {
      locale:{
        format: appl.cof.moment.fmt_dt,
      },
      ranges: {
         'Today': [moment().startOf('day'), moment().endOf('day')],
         'Yesterday': [moment().startOf('day').subtract('days', 1), moment().endOf('day').subtract('days', 1)],
         'Last 7 Days': [moment().startOf('day').subtract('days', 6), moment().endOf('day')],
         'Last 30 Days': [moment().startOf('day').subtract('days', 29), moment().endOf('day')],
         'This Month': [moment().startOf('day').startOf('month'), moment().endOf('day').endOf('month')],
         'Last Month': [moment().startOf('day').subtract('month', 1).startOf('month'), moment().endOf('day').subtract('month', 1).endOf('month')]
      },
      startDate: moment().startOf('day'),
      endDate: moment().endOf('day'),
      timePicker: true,
      minDate: moment().startOf('day').subtract('day',gon.min_days_search),
      maxDate: moment().endOf('day'),
      timePicker24Hour: true,
      timePickerIncrement: 1,
      dateLimit: { days: gon.searchopts.dayslimit }
    };
    $("#cs-period").daterangepicker(options).on('blur',function(start, end, label){
      if (isBlank($("#cs-period").val())){
        init.setTodayPicker(); 
      }
    });
    init.setTodayPicker();
  },
  bindButtons: function(){
    
    function goToRow(pos){
      if (pagi.isNotEmpty){
        var rn = parseInt(sh.currentPlayingRowNo) + pos;
        var id = "#row-no-" + rn;
        var o = $("#tbl-voicelogs table tbody").find(id);
        if (o.length <= 0){
          if (pos > 0) {
            rn = parseInt(sh.paginate.first_row_no);
          } else {
            rn = parseInt(sh.paginate.last_row_no); 
          }
          id = "#row-no-" + rn;
          o = $("#tbl-voicelogs table tbody").find(id);
        }
        sh.currentPlayingRowNo = rn;
        o.find(".button-play-sound").trigger("click");
      }
    }
    
    $("#btn-find-call").on("click",function(){
      pagi.clear();
      sh.findAndShow();
    });
    
    $("#btn-prev-track").on("click",function(){
      goToRow(-1);
    });
    
    $("#btn-next-track").on("click",function(){
      goToRow(1);
    });
    
    $("#btn-toggle-option").click(function () {
      $("#more-option").slideToggle({
        "duration" : 150,
        "step" : reSizeTableView
      });
    });
    
    $("#btn-toggle-audioview").click(function () {
      $("#audioview").slideToggle({
        "duration": 150,
        "step" : reSizeTableView
      });
      $(this).find('i').toggleClass('fa-chevron-up fa-chevron-down');
    });
    
    $("#btn-clear").click(function () {
      $(this).closest('form')[0].reset();
      $(".btn-group .btn").removeClass("active");
      $("#cs-direction-both").closest(".btn").addClass("active");
      init.setTodayPicker();
    });
    
    $("#cs-text").on('keypress keyup keydown change',function(){
      var o = $(this);
      if(jQuery.trim(o.val()).length > 0){
        $("#tbl-search-field .no-text-search").find('input').prop("disabled",true);
        $("#tbl-search-field .no-text-search").find('select').prop("disabled",true);
      } else {
        $("#tbl-search-field .no-text-search").find('input').prop("disabled",false);
        $("#tbl-search-field .no-text-search").find('select').prop("disabled",false);
      }
    });
    
    $("#bt-export-call").on("click",function(){
      var htm = appl.getHTML("#export-dialog-templete");
      bootbox.dialog({
        className: "call-export-dialog",
        title: "Export",
        message: htm,
        buttons: {
          save: {
            label: "Export",
            className: "btn-primary",
            callback: function(){
              var url = Routes.export_voice_logs_path();
              var opts = {
                ftype: $(".call-export-dialog #file_type option:selected").val()
              };
              var parms = {
                search: sh.currentSearchKey,
                paginate: sh.paginate,
                opts: opts
              };
              appl.dialog.showWaiting();
              jQuery.getJSON(url,parms,function(data){
                waitForDownload(data.file_id);
              });
            }
          },
          cancel: {
            label: "Cancel",
            className: "btn-default"
          }
        }
      });
    });
    
    $("#search-panel form input[type=text]").keypress(function(e){
      if (e.which == 13){
        pagi.clear();
        sh.findAndShow();
      }
    });
    
    $("#btn-only-fav").on('click',function(){
      $(this).toggleClass('only-fav-call');
      sh.findAndShow();
    });
  },
  
  setPaginate: function(){
    
    sh.paginate.perpage = gon.paginate.permin;
    pagi.updateInfo();
    
    $("#pg-pages").on("click",function(){
      $(this).val(sh.paginate.current_page);
    }).on('blur',function(){
      pagi.gotoPage(parseInt($(this).val()));
    });
    $("#pg-perpage").on('blur',function(){
      pagi.setPerpage(parseInt(jQuery.trim($(this).val())));
    });
    $("#pg-first-page").on("click",function(){
      pagi.firstPage();
    });
    $("#pg-next-page").on("click",function(){
      pagi.nextPage();
    });
    $("#pg-prev-page").on("click",function(){
      pagi.prevPage();
    });
    $("#pg-last-page").on("click",function() {
      pagi.lastPage();
    });
  },
  setInputFields: function(){
    function setAtlSectionField(){
      var oc = $("#cs-atlsection");
      if(isFoundElement(oc)){
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
            data.phrase = oc.val();
            return data;
          },
          requestDelay: 300
        };
        oc.easyAutocomplete(options);   
      }
    }
    
    appl.autocomplete.setAgentAutoCompleteField("cs-agent", { unknown: true });
    appl.autocomplete.setGroupAutoCompleteField("cs-group");
    appl.autocomplete.setTagAutoCompleteField("cs-tags");
    setAtlSectionField();
  },
  setColumnOrder: function(){
    $("#tbl-voicelogs table thead th").each(function(d){
      var c = $(this);
      if (c.hasClass("sort_dt")){
        c.removeClass("desc").removeClass("asc");
        if (c.attr("data-col") == sh.paginate.order_col) {
          c.addClass(sh.paginate.order_by);
        }
      }
    });
  },
  preLoadParam: function(){
    var gotParm = false;
    if (isSet(gon.params.d)){
       $("#cs-period").val(gon.params.d + " 00:00 - " + gon.params.d + " 23:59");
       gotParm = true;
    }
    if (isSet(gon.params.w) && isSet(gon.params.y)) {
      var w = moment().year(parseInt(gon.params.y)).week(parseInt(gon.params.w)-1);
      $("#cs-period").val(w.startOf('week').format('YYYY-MM-DD 00:00') + " - " + w.endOf('week').format('YYYY-MM-DD 23:59'));
      gotParm = true;
    }
    if (isSet(gon.params.m) && isSet(gon.params.y)) {
      var m = moment().year(parseInt(gon.params.y)).month(gon.params.m);
      $("#cs-period").val(m.startOf('month').format('YYYY-MM-DD 00:00') + " - " + m.endOf('month').format('YYYY-MM-DD 23:59'));
    }
    if (isSet(gon.params.ym)) {
      var yy = gon.params.ym.toString().substring(0,4);
      var mm = gon.params.ym.toString().substring(4,6);
      var ym = moment().year(parseInt(yy)).month(parseInt(mm)-1);
      $("#cs-period").val(ym.startOf('month').format('YYYY-MM-DD 00:00') + " - " + ym.endOf('month').format('YYYY-MM-DD 23:59'));
      gotParm = true;
    }
    if (isSet(gon.params.fr_d) && isSet(gon.params.to_d)) {
      $("#cs-period").val(gon.params.fr_d + " 00:00 - " + gon.params.to_d + " 23:59");
      gotParm = true;
    }
    if (isSet(gon.params.word) && isSet(gon.params.word)) {
      $("#cs-text").val(gon.params.word);
      gotParm = true;
    }
    if (isSet(gon.params.class_id)) {
      $("#cs-flag option[value=" + gon.params.class_id +"]").prop("selected",true);
    }
    if (isSet(gon.params.cates)){
      var cates = gon.params.cates.split(",");
      cates.forEach(function(c){
        $("select.cs-flag").each(function(){
          var t = $(this);
          $("option[value=\"" + c + "\"]",t).prop("selected",true);
        });
      });
    }
    if (isSet(gon.params.dir)){
      if (gon.params.dir == 'i') {
        $("#cs-direction-in").trigger("click");     
      } else if (gon.params.dir == 'o') {
        $("#cs-direction-out").trigger("click");
      }
    }
    if(isSet(gon.params.dur_fr)){
      $("#cs-duration-from").val(gon.params.dur_fr);
    }
    if(isSet(gon.params.dur_to)){
      $("#cs-duration-to").val(gon.params.dur_to);
    }
    if (isSet(gon.params.caller)) {
      $("#cs-caller").val(gon.params.caller);
      gotParm = true;
    }
    if (isSet(gon.params.dialed)) {
      $("#cs-dialed").val(gon.params.dialed);
      gotParm = true;
    }
    if(isSet(gon.params.agent_name)){
      $("#cs-agent").val(gon.params.agent_name);
      gotParm = true;
    }
    if(isSet(gon.params.group_name)){
      $("#cs-group").val(gon.params.group_name);
      gotParm = true;
    }
    if (isSet(gon.params.u)) {
      gotParm = true;
    }
    if (isSet(gon.params.kw)) {
      gotParm = true;
    }
    if (isSet(gon.params.rsn)){
      // call reason
      $("#cs-reasons").val(gon.params.rsn);
    }
    
    if(isSet(gon.params.findnow)){
      gotParm = true;
    }
    
    if (gotParm){
      sh.findAndShow();
    }
  }
};

var pagi = {
  updateInfo: function(){
    $("#pg-r-from").text(sh.paginate.first_row_no);
    $("#pg-r-to").text(sh.paginate.last_row_no);
    $("#pg-pages").val(sh.paginate.current_page + " of " + sh.paginate.total_pages);
    $("#pg-pages").qtip('option','content.text',"Maximum page is " + sh.paginate.total_pages);
    $("#pg-perpage").val(sh.paginate.perpage);
  },
  nextPage: function(){
    if (sh.paginate.current_page < sh.paginate.total_pages) {
      sh.paginate.current_page += 1;
      sh.findAndShow();
    }
  },
  prevPage: function(){
    if (sh.paginate.current_page > 1) {
      sh.paginate.current_page -= 1;
      sh.findAndShow();
    }
  },
  firstPage: function(){
    if (sh.paginate.current_page != 1) {
      sh.paginate.current_page = 1;
      sh.findAndShow();
    }
  },
  lastPage: function(){
    if (sh.paginate.current_page != sh.paginate.total_pages) {
      sh.paginate.current_page = sh.paginate.total_pages + 0;
      sh.findAndShow();
    }
  },
  setPerpage: function(v){
    if ((v != sh.paginate.perpage) && (v >= gon.paginate.permin) && (v <= gon.paginate.permax)) {
      sh.paginate.perpage = v;
      sh.findAndShow();
    } else {
      this.updateInfo();
    }
  },
  gotoPage: function(v){
    if ((v != sh.paginate.current_page) && (v > 0) && (v <= sh.paginate.total_pages)){
      sh.paginate.current_page = v;
      sh.findAndShow();
    } else {
      pagi.updateInfo();
    }
  },
  clear: function(){
    sh.paginate.current_page = 1;
  },
  isEmpty: function(){
    return (sh.paginate.total_records <= 0);
  },
  isNotEmpty: function(){
    return (sh.paginate.total_records > 0);
  }
}

function waitForDownload(file_id){
  var url = Routes.export_voice_logs_path();
  jQuery.getJSON(url,{ file_id: file_id },function(data){
    if (data.status === null) {
      setTimeout("waitForDownload('"+file_id+"')",2500);
    } else {
      $.fileDownload(Routes.export_voice_logs_path({ file_id: file_id, download:"true" }),{
        failCallBack: function(url){ alert("error!"); }
      });
      appl.dialog.hideWaiting();
    }
  });
}

function minMaxSearchPanel()
{
  function resetPanel()
  {
    /* fixed position problem */
    $("#panel-sub-groupfields").scrollTop(0);
    resizeDisplayTable();
  }
  
  function resetPanelDelay()
  {
    setTimeout(resetPanel,100);
  }
  
  $("#btn-showhide-search").on('click',function(){
    var o = $(this);
    var p = $("#search-panel .panel-group-left");
    if (o.attr("data-show-state") == "show") {
      o.attr("data-show-state","hide");
      p.addClass("minimize-panel");
    } else {
      o.attr("data-show-state","show");
      p.removeClass("minimize-panel");
    }
    resetPanel();
  });
  
  resetPanelDelay();
}

function resizeDisplayTable()
{
  var wh = $(window).height() - $("#panel-app-header").outerHeight();
  var ps = 0;
  if($("#search-panel").css('display') !== 'none'){
    ps = $("#search-panel").outerHeight();
  }
  var pi = $("#panel-tbl-info").outerHeight();
  var pa = $("#audioplayer").outerHeight();
  var pv = $("#audioview").outerHeight();
  if ($("#audioview").css("display") == "none") { pv = 0; }
  
  var rh = wh - (ps + pi + pa + pv);
  
  var oc = $("#panel-display-call-hist");
  oc.height(rh);
  var tv = $("#tbl-voicelogs");
  tv.height(rh);
  
  $('#tbl-voicelogs .dataTables_scrollBody').css('height',rh - $('#tbl-voicelogs .dataTables_scrollHead').height());
  if(vlTable && (vlTable !== undefined)){
    vlTable.columns.adjust();
  }
}

function reSizeTableView(){
  resizeDisplayTable();
}

jQuery(document).on('ready page:load',function(){
  if(gon.params.spnl !== "no"){
    $("#search-panel").removeClass('hide-panel');
  }
  $("input#cs-duration-from").qtip({ content: { text: 'format: MMSS' }});
  $("input#cs-duration-to").qtip({ content: { text: 'format: MMSS' }});
  $("input#cs-period").qtip({ content: { text: 'format: yyyy-mm-dd - yyyy-mm-dd' }});
  appl.dialog.showWaiting();
  init.setDateTimePicker();
  init.bindButtons();
  init.setPaginate();
  init.setInputFields();
  minMaxSearchPanel();
  reSizeTableView();
  sh.loadToTable({});
  $(window).resize(reSizeTableView);
  appl.dialog.hideWaiting();
  init.preLoadParam();
  callInfo.initPreload();
});