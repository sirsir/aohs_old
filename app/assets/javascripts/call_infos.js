var callInfo = {
  _mainVolId: 0,
  _currentVolId: 0,
  _gotTransLogs: false,
  _lastSelTransRowNo: -1,
  _tmp: {},
  
  ds: null,
  
  list: {
    tags: null
  },
  
  voice_id: null,
  
  __showTranscription: function(data){
    
    function updateTranscription(trans){
      var url = Routes.update_transcription_voice_log_path(callInfo._currentVolId);
      jQuery.post(url,jQuery.extend({
        transcription: trans
      },appl.defaultPostParams()),function(){});
    }
    
    function restoreChanged(){
      var url = Routes.update_transcription_voice_log_path(callInfo._currentVolId);
      jQuery.post(url,jQuery.extend({
        transcription: { channel: 'all', text: '<restore>' }
      },appl.defaultPostParams()),function(){});
      $("button#btn-reset-alltrans").removeClass('btn-hidden');
    }
    
    var htm = appl.hbsTemplate("trans-log-template");
    var ot = $("#tb-call-trans");
    if(isFoundElement(ot)){
      ot.html(htm(data));
      
      if(data.length > 0){
        var pn = $("#td-cdt-2");
        if(isFoundElement(pn)){
          pn.removeClass('hide-panel');
        }
        callInfo._gotTransLogs = true;
        callInfo._lastSelTransRowNo = -1;
      }
      
      $("tr.playat", ot).off('dblclick').on('dblclick', function(){
        var o = $(this);
        ap.seek(parseFloat(o.attr('data-start-sec'))*1000);
      });
      
      //$("button#btn-reset-alltrans").off('click').on('click',function(){
      //  bootbox.confirm("Are you sure to reset all transcription",function(result){
      //    if(result){
      //      $("button#btn-reset-alltrans").addClass('btn-hidden');
      //    }
      //  });  
      //});
      
      $("button.btn-edit-trans",ot).off('click').on('click',function(){
        var oa = $(this);
        var od = oa.closest('td.trans_rs');
        var or = od.closest('tr');
        var hr = od.height() + 14;
        $('button.btn-on-edit',od).removeClass('btn-hidden');
        $('button.btn-on-init',od).addClass('btn-hidden');
        $('div.fd-edit',od).removeClass('hide-block');
        $('div.fd-text',od).addClass('hide-block');
        $('textarea',od).val($('div.fd-text',od).text()).focus();
        $('textarea',od).height(hr);
        $('textarea',od).off('keypress keyup').on('keypress keyup',function(e){
          if(e.keyCode == 13){
            e.preventDefault();
          } else if(e.keyCode == 27){
            $('button.btn-edit-cancel',od).trigger('click');
          }
        });
        
        if(or.attr("data-edited-flag") !== "yes"){
          $("button.btn-edit-undo",od).addClass('btn-hidden');
        }
        or.addClass('row-editing');
        
        $('button.btn-edit-ok',od).off('click').on('click',function(){
          $('button.btn-on-edit',od).addClass('btn-hidden');
          $('button.btn-on-init',od).removeClass('btn-hidden');
          $('div.fd-edit',od).addClass('hide-block');
          $('div.fd-text',od).removeClass('hide-block');
          $('textarea',od).height(1);
          var ds = {
            channel: or.attr('data-channel'),
            text: $('textarea',od).val(),
            start_sec: or.attr('data-start-sec')
          };
          $('div.fd-text',od).html(ds.text);
          or.attr("data-edited-flag","yes");
          updateTranscription(ds);
          or.removeClass('row-editing');
        });
        
        $('button.btn-edit-undo',od).off('click').on('click',function(){
          $('button.btn-on-edit',od).addClass('btn-hidden');
          $('button.btn-on-init',od).removeClass('btn-hidden');
          $('div.fd-edit',od).addClass('hide-block');
          $('div.fd-text',od).removeClass('hide-block');
          $('textarea',od).height(1);
          var ds = {
            channel: or.attr('data-channel'),
            text: "<delete>",
            start_sec: or.attr('data-start-sec')
          };
          $('div.fd-text',od).html(or.attr("data-recogn-result"));
          or.attr("data-edited-flag","no");
          or.addClass('row-editing');
          updateTranscription(ds);
        });
        
        $('button.btn-edit-cancel',od).off('click').on('click',function(){
          $('button.btn-on-edit',od).addClass('btn-hidden');
          $('button.btn-on-init',od).removeClass('btn-hidden');
          $('div.fd-edit',od).addClass('hide-block');
          $('div.fd-text',od).removeClass('hide-block');
          $('textarea',od).height(1);
          or.removeClass('row-editing');
        });
        
      });
    }
    
    data = null;
    htm = null;
  },
  
  __showAnaResult: function(){
    function renderData(data){
      if(!isBlank(data.msg_logs)){
        var htm = appl.hbsTemplate("template-anaresult-msglogs");
        $("div#block-anaresult-msglogs").html(htm(data.msg_logs));
        fnShow.resize();
      }
      appl.dialog.hideWaiting();
    }
    
    function isLoaded(){
      try {
        return callInfo._tmp.fgAnaLoaded == true;
      } catch(e){
        return false;
      }
    }
    
    function displayAndLoad(){
      jQuery.getJSON(Routes.ana_result_logs_voice_log_path(callInfo._currentVolId),{},function(data){
        renderData(data);
      });
    }
    
    if(!isLoaded()){
      callInfo._tmp.fgAnaLoaded = true;
      appl.dialog.showWaiting();
      displayAndLoad();
    }
  },
  
  __showDetectedKeyword: function(data){
    function renderKeyword(){
      var keyws = [];
      var ow = $("#box-keyword-list");
      var htm = appl.hbsTemplate("template-callinf-keywords");
      if(data.list !== undefined){
        try {
          data.list.forEach(function(words){
            words.forEach(function(w){
              keyws.push({ text: w.text, cssClass: w.css_class });  
            });
          });
        } catch(e){}
        ow.css("display","block");
      }
      /* show keywords */
      keyws = keyws.unique().sort();
      ow.html(htm(keyws));
      if(keyws.length > 0){
        $("#tb-call-trans span.content-keyword").each(function(){
          var o = $(this);
          o.attr("data-text", o.text());
        });
        /* point to keyword */
        $(".content-keyword",ow).off('click').on('click',function(){
          try {
            var toffset = $("#tb-call-trans span.content-keyword[data-text=\"" + $(this).text() + "\"]").first().position().top;
            toffset = toffset + $(".trans-result.block-scroll").scrollTop() - $(".trans-result.block-scroll").height()/4;
            $(".trans-result.block-scroll").animate({
              scrollTop: toffset
            });   
          } catch(e){}
        });
      }
      /* clear data */
      data = null;
    }
    
    function highlightFindWords(){
      if(appl.hasCookies()){
        try {
          var word = Cookies.get("keycallsearch-text");
          if (word.length > 0){
            $("#tb-call-trans tr").highlight(word,{ className: "content-keyword found-word" });
          }
        } catch(e){}
      }
    }
    
    renderKeyword();
    highlightFindWords();
  },
  
  __showDetectedTopic: function(data){
    if(data !== null){
      data.forEach(function(t){
        var spos = ap.awf.getPxPosition(t.start_msec/1000);
        var epos = ap.awf.getPxPosition(t.end_msec/1000);
        jQuery('<div>',{ width: (epos-spos), class: 'cl-topic cl-topic-0', text: t.label }).appendTo("#box-topics");
      });      
    }
  },
  
  __showDsrStat: function(data){
    function renderHtml(data){
      var htm = appl.hbsTemplate("template-speech-recg-info");
      $("#block-speech-recg-info").html(htm(data));
    }
    renderHtml(data);
  },

  __showCallStats: function(data){
    function renderStat(data){
      var htm = appl.hbsTemplate("template-call-stats-info");
      $("#block-voicestats-info").html(htm(data));
      data = null;
    }
    renderStat(data);
    data = null;
  },
  
  __showOptionInfo: function(data){
    function showInfo(data){
      var htm = appl.hbsTemplate("template-additional-info");
      $("#box-additional-info > div").html(htm(data));
      data = null;
    }
    showInfo(data);
    data = null;
  },
  
  _loadCallTrans: function(){
    
    function waitPlayerReady(){
      if((gon.audioplayer != undefined) && gon.audioplayer.waveform.disabled == true){
        return true;
      }
      return ((ap !== undefined) && (ap.awf !== undefined) && (ap.awf !== null) && (ap.awf.loadSuccess()));
    }
    
    function tryResizePageShow(){
      try {
        if(fnShow !== undefined){
          fnShow.resize();
        }
      } catch(e){}
    }
    
    function loadCallInfo(){
      appl.dialog.showWaiting();
      jQuery.getJSON(Routes.trans_log_voice_log_path(callInfo._currentVolId), function(d){
        callInfo.ds = d;
        callInfo.__showTranscription(d.trans);
        callInfo.__showDetectedKeyword(d.detected_keywords);
        callInfo.__showDsrStat(d.dsrstats);
        callInfo.__showCallStats(d.callstats);
        callInfo.__showDetectedTopic(d.topics);
        callInfo.__showOptionInfo(d.additional_details);
        tryResizePageShow();
        appl.dialog.hideWaiting();
        //callInfo.showDesktopLog(d.desktop);
        //callInfo.showAnnotation(d.events);
        //callInfo.showCallReason(d.reasons);
        d = null;
      });
    }
    
    callInfo._gotTransLogs = false;
    setTimeout(function(){
      if(!waitPlayerReady()){
        callInfo._loadCallTrans();  
      } else {
        loadCallInfo();
      }
    },50);
  },
  
  highlightRowAtSec: function(sec){
    /* focus to target row by sec-posiion */
    if(callInfo._gotTransLogs){
      var rNo = -1, rCnt = callInfo.ds.trans.length;
      for(var i=0; i<rCnt; i++){
        var r = callInfo.ds.trans[i];
        if ((sec > r.ssec) && (sec <= r.esec)) {
          rNo = r.no;
          break;
        }
      }
      if((rNo > 0) && (rNo != callInfo._lastSelTransRowNo)){
        callInfo._lastSelTransRowNo = rNo;
        var ro = $("#tb-call-trans tr#trx-no-" + rNo);
        if(!ro.hasClass("trx-current")){
          $("#tb-call-trans tr").removeClass("trx-current");
          ro.addClass("trx-current");
          if($("#btn-auto-scroll").attr("data-auto-scroll") !== "false"){
            var cont = $("#pnl-trans .block-scroll");
            var moveTo = ro.offset().top - cont.offset().top + cont.scrollTop() - cont.height()/2;
            cont.scrollTop(moveTo);
          }
        }
      }
    }
  },
  
  showDesktopLog: function(ds)
  {
    function displayList(list)
    {
      list.forEach(function(l){
        var spos = ap.awf.getPxPosition(l.spos);
        var epos = ap.awf.getPxPosition(l.epos);
        var o_opts = {
          width: (epos - spos),
          class: ['box-segment',l.css].join(" "),
          text: l.display_name
        };
        jQuery('<div>',o_opts).appendTo("#box-events");
      });
    }
    
    function displaySummary(list) {
      var o = $("#box-user-activity div");
      o.html("");
      list.forEach(function(l){
        o.append("<div class=\"progress\"><div class=\"progress-bar progress-bar-" + l.css + "\" role=\"progressbar\" aria-valuenow=\"" + l.percentage +"\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width:" + l.percentage + "%\">" + l.display_name + "</div></div>");  
        $("#tbl-app-usage tbody").append("<tr><td>" + l.display_name + "</td><td>" + l.duration_fmt + "</td><td></td></tr>");
        l.detail.forEach(function(l2){
          $("#tbl-app-usage tbody").append("<tr><td></td><td>" + l2.duration_fmt + "</td><td>" + l2.title + "</td></tr>"); 
        });
      });
    }
    
    if(isPresent(ds)){
      try{
        displayList(ds.list);
        displaySummary(ds.summary);            
      } catch(e){}
    }
  },
  
  showCallReason: function(list){
    list.forEach(function(t){
      jQuery('<tr>').append("<td>" + t.title + "</td>").appendTo("#box-call-reason table");  
    });
  },
  
  showAnnotation: function(d)
  {
    d.forEach(function(a){
      ap.awf.createPosition(a.ssec, a.title);
    });
  },
  
  showCallType: function(){},
  
  checkPrivateCall: function(id, isPrivate){
    function update(){
      var pvt = gon.call_categories.find(function(c){
        return c.code_name == "private";
      });
      var update_opt = { code: pvt.id, result: isPrivate.toString()};
      jQuery.getJSON(Routes.call_type_voice_log_path(id), update_opt, function(){});
    }
    update();
  },
  
  _displayCallType: function(updateOptions){
    function setButton(){
      var o = $("#block-call-type-list");
      if(isFoundElement(o)){
        $("button.btn-remove-calltype",o).off('click').on('click',function(){
          var b = $(this);
          bootbox.confirm("Are you sure to remove this", function(result){
            if(result){
              var c = b.closest('.text-symbol');
              callInfo._displayCallType({ code: c.attr('data-call-category-id'), result: false });
              c.remove();
            }
          });
        });
      }
    }
    
    function getCallType(){
      var url = Routes.call_type_voice_log_path(callInfo._currentVolId);
      var o = $("#block-call-type-list");
      if(isFoundElement(o)){
        o.html("");
        jQuery.getJSON(url,updateOptions,function(data){
          var htm = appl.hbsTemplate("template-calltype-btn");
          var isNoData = true;
          data.forEach(function(d){
            if (d.result) {
              o.append(htm({ id: d.code, title: d.title }));
              isNoData = false;
            }
          });
          if(isNoData){
            o.html("-");
          }
          setButton();
        });
      }
    }
    
    getCallType();
  },

  _displayCallTag: function(updateOptions){
    function setButton(){
      var o = $("#block-call-tag-list");
      $("button.btn-remove-calltype",o).off('click').on('click',function(){
        var b = $(this);
        bootbox.confirm("Are you sure to remove this", function(result){
          if(result){
            var c = b.closest('.text-symbol');
            callInfo._displayCallTag({ code: c.attr('data-tag-id'), result: false });
            c.remove();
          }
        });
      });
    }
    
    function getCallTag(){
      var url = Routes.call_tagging_voice_log_path(callInfo._currentVolId);
      var o = $("#block-call-tag-list");
      o.html("");
      jQuery.getJSON(url,updateOptions,function(data){
        var htm = appl.hbsTemplate("template-calltag-btn");
        var isNoData = true;
        data.forEach(function(d){
          o.append(htm({ id: d.id, title: d.title }));
          isNoData = false;
        });
        if(isNoData){
          o.html("-");
        }
        setButton();
      });
    }
    
    getCallTag();
  },

  _showCallComments: function() {
    
    function updateComment(o) {
      var ct = getVal(o.parent().find("textarea").val());
      var ci = o.attr("data-comment-id") || 0;
      if (isNotBlank(ct)){
        var url = Routes.update_comment_voice_log_call_comments_path({voice_log_id: callInfo._currentVolId});
        jQuery.post(url,{ id: ci, comment: ct }, function(data){
          if (data.success){ updateView(); }
          appl.noty.success("Comment has been updated.");
        });
      }
    }
    
    function deleteComment(o){
      var ci = o.attr("data-comment-id");
      if (isNotBlank(ci)){
        appl.dialog.deleteConfirm2(function(){
          var url = Routes.delete_comment_voice_log_call_comments_path({voice_log_id: callInfo._currentVolId});
          jQuery.post(url,{ id: ci },function(){
            updateView();
            appl.noty.success("Comment has been removed.");
          });
        });
      }
    }
    
    function appendToView(ds){
      var htm_tempate = appl.getHtmlTemplate("#comments-template");
      var o = $("#call-comments-body");
      o.html(htm_tempate(ds));
      o.find(".written-comment").css("display","none");
      o.find(".btn-update-comment").on('click',function(){
        updateComment($(this));
      });
      o.find(".btn-delete").on('click',function(){
        deleteComment($(this));
      });
      o.find("textarea[name=comment]").on("keypress keyup",function(){
        if($(this).val().length > 3){
          o.find("button[name=update-comment]").removeAttr("disabled");  
        } else {
          o.find("button[name=update-comment]").attr("disabled","disabled");  
        }
      });
    }
    
    function updateView(){
      var url = Routes.list_voice_log_call_comments_path({ id: callInfo._currentVolId });
      jQuery.getJSON(url,function(data){
        appendToView(data);
      });
    }
    
    updateView();
  },
  
  _audiofileDownload: function(){
    function fileDownload(fileType){
      appl.fileDownload(appl.mkUrl(Routes.download_voice_log_path(callInfo._currentVolId),{ ftype: fileType }));
    }
    var fileType = $("#dl-file-type").val();
    if(fileType === undefined){
      var htm = appl.hbsTemplate("template-audiofile-download-dialog");
      var opts = {
        message: htm(),
        size: "small",
        buttons: {
          cancel: {
            label: 'Cancel',
            className: 'btn-default'
          }
        }
      };
      appl.__dialogDlAudioFile = bootbox.dialog(opts);
      appl.__dialogDlAudioFile.init(function(){
        $('button.btn-dl-audiofile',this).off('click').on('click',function(){
          var ob = $(this);
          fileDownload(ob.attr("data-file-format"));
          appl.__dialogDlAudioFile.modal('hide');
        });
      });
    } else {
      fileDownload(fileType);
    }
  },
  
  _selectorCallTag: null,
  _initCallTag: function(){
    function formatDisplay (data) {
      if (!data.id) { return data.text; }
      return $('<span/>',{ class: "bd-left-tag", "data-tag-id": data.id, text: data.text });
    }
    function addTypeTag(id, title){
      var htm = appl.getHtmlTemplate("#template-calltype-btn");
      $("#block-call-tag-list").append(htm({ id: id, title: title }));
      callInfo._displayCallTag({ code: id, result: true });
    }
    var o = $("select#fl-call-tag");
    if(o.length > 0){
      var opts = {
        width: 160,
        ajax: {
          url: Routes.list_tags_path(),
          dataType: 'json',
          cache: true,
          data: function (params) {
            return { q: params.term };
          },
          processResults: function(data, page){
            return { results: data };
          }
        },
        templateResult: formatDisplay
      };
      callInfo._selectorCallTag = o.select2(opts);
      o.on('select2:select',function(){
        var p = $(this);
        if(p.val() !== null && p.val().length > 0){
          addTypeTag(p.val(),p.text());
          callInfo._selectorCallTag.val(null).trigger("change");
          $("select#fl-call-tag").html("");
        }
      });
      $("#btn-add-calltag").off('click').on('click',function(){
        callInfo._selectorCallTag.select2("open");  
      });
    }
  },
  
  _selectorCallType: null,
  _initCallType: function(){
    
    function formatDisplay (data) {
      if (!data.id) { return data.text; }
      return $('<span/>',{ class: "text-symbol-option", "data-call-category": data.text, text: data.text });
    }
    
    function addTypeTag(id, title){
      var htm = appl.getHtmlTemplate("#template-calltype-btn");
      $("#block-call-type-list").append(htm({ id: id, title: title }));
      callInfo._displayCallType({ code: id, result: true });
    }
    
    function createSelector(){
      var o = $("select#fl-call-type");
      var opts = {
        width: 160,
        ajax: {
          url: Routes.list_call_categories_path(),
          dataType: 'json',
          cache: true,
          data: function(params){ return { q: params.term }; },
          processResults: function(data, page) { return { results: data }; }
        },
        templateResult: formatDisplay
      };
      callInfo._selectorCallType = o.select2(opts);
      o.on('select2:select',function(){
        var p = $(this);
        if(p.val() !== null && p.val().length > 0){
          addTypeTag(p.val(),p.text());
          callInfo._selectorCallType.val(null).trigger("change");
          $("select#fl-call-type").html("");
        }
      });
    }
    
    function initSelector(){
      var o = $("select#fl-call-type");
      if(o.length > 0){
        createSelector();
        $("#btn-add-calltype").off('click').on('click', function(){
          callInfo._selectorCallType.select2("open");  
        });
      }
    }
    
    initSelector();
  },
  
  _initEvent: function(){
    /* file download */
    var odl = $("#btn-file-download");
    if(isFoundElement(odl)){
      odl.off('click').on("click", function(){
        callInfo._audiofileDownload();
      });
    }
    
    /* transcription download */
    var odt = $("button.btn-download-trans");
    if(isFoundElement(odt)){
      odt.off("click").on("click",function(){
        appl.fileDownload(Routes.trans_file_voice_log_path(callInfo._currentVolId));
      });
    }
  },
  
  /* to initial load main call */
  loadMainCall: function(m_id){
    callInfo._currentVolId = m_id || 0;
    callInfo._mainVolId = callInfo._currentVolId;
    if(callInfo._currentVolId){
      if(gon.params.action == 'show'){
        callInfo._initCallType();
        callInfo._initCallTag();
        callInfo._displayCallType();
        callInfo._displayCallTag();
        callInfo._loadCallTrans();
      } else {
        callInfo._displayCallType();
        callInfo._displayCallTag();
      }
      callInfo._showCallComments();
      callInfo._initEvent();
    }
  },
  
  /* to inital load releated calls - current */
  loadReleatedCall: function(r_id){
    callInfo._currentVolId = r_id || 0;
    if(callInfo._currentVolId){
      callInfo._initCallType();
      callInfo._initCallTag();
      callInfo._displayCallType();
      callInfo._displayCallTag();
      callInfo._loadCallTrans();
      callInfo.showCallComments();
    }
  },
  
  initPreload: function(){
    callInfo._initCallType();
    callInfo._initCallTag();
  },
  
  showAll: function(id){
    callInfo.loadMainCall(id);
    callInfo.voice_id = id;
    if(gon.params.action == 'show'){
      callEvaluate.init();
    }
  }
};

var callEvaluate = {
  formId: null,
  formRevisionNo: null,
  useOnlySummaryComment: null,
  ds: {},
  evaluateState: 'new',
  evaluateStateCheck: 'yes',
  agentId: 0,
  requireAttachmentDialog: false,
  requireCloseMsg: false,
  slbGroup: null,
  
  isDefinedForm: function(){
    return (callEvaluate.formId !== 0);
  },
  
  showMsg: function(msg){
    var o = $("#box-evl-msg");
    if(msg.length>0){
      o.html("<div class=\"alert alert-warning\">" + msg + "</div>");
    } else {
      o.html("");
    }
  },
  
  loadForm: function()
  {
    var dsForm;
    
    function setHandler() {
      var obe = $("#box-evaluation-form .btn-quest-comment");
      obe.off('click');
      if(dsForm.use_only_summary_comment){
        obe.css("display","none");
      } else {
        obe.on('click',function(){
          var o = $(".block-quest-comment",$(this).closest('div.block-question'));
          if(o.length > 0){
            if(o.hasClass('hide-comment')){
              o.removeClass('hide-comment');
            } else {
              o.addClass('hide-comment');
            }
          }
        });
      }
    }

    function renderForm() {
      var htm = appl.getHtmlTemplate("#template-evaluation-form");
      var o = $("#box-evaluation-form");
      o.html(htm(dsForm.data));
      if(!dsForm.show_group_question){
        $(".txt-group-title",o).css("display","none");
      }
      $("#evl_comment").val("");
      $("#box-doc-attachment").addClass('hide-box');
      callEvaluate.showMsg("");
    }
    
    function isCallToEvaluate(){
      try {
        if(gon.evaluation.min_duration_sec > 0){
          if(fnShow.dsCall.duration_sec < gon.evaluation.min_duration_sec){
            return false;
          }
        }
      } catch(e){}
      return true;
    }
    
    /* begin */
    if (isCallToEvaluate() && callEvaluate.isDefinedForm()){
      appl.dialog.showWaiting();
      callEvaluate.iCheckSetup('destroy');
      jQuery.get(Routes.list_evaluation_plan_evaluation_criteria_path({
        evaluation_plan_id: callEvaluate.formId,
        voice_log_id: gon.params.id
      }),function(data){
        dsForm = data;
        renderForm();
        setHandler();
        callEvaluate.formRevisionNo = parseInt(data.revision_no);
        callEvaluate.setFormState('new');
        callEvaluate.useOnlySummaryComment = data.use_only_summary_comment;
        callEvaluate.loadEvaluatedResult();
      });
    } else {
      $("#box-inprocessing").addClass('hide-block');
      $("div.box-oper-info").addClass('hide-block');
      $("div.box-summary-comment").addClass('hide-block');
      $("div#box-no-available-form").removeClass('hide-block');
    }
  },
  
  setFormState: function(state)
  {
    callEvaluate.evaluateState = state;
    
    function hideBtn(btno) {
      btno.addClass('btn-hidden');
    }
    
    function showBtn(btno) {
      btno.removeClass('btn-hidden');
    }
    
    function disableForm() {
      var o = $("#box-evaluation-form");
      $("input", o).prop('disabled', true);
      $("select", o).prop('disabled', true);
      var p = $("#box-summary-comment");
      $("textarea", p).prop('disabled', true);
      var q = $("#box-oper-info");
      $("select", q).prop('disabled', true);
      callEvaluate.iCheckSetup('update');
    }
    
    function enableForm(){
      var o = $("#box-evaluation-form");
      $("input", o).prop('disabled',false);
      $("select", o).prop('disabled', false);
      var p = $("#box-summary-comment");
      $("textarea", p).prop('disabled', false);
      var q = $("#box-oper-info");
      $("select", q).prop('disabled', false);
      callEvaluate.iCheckSetup('update');
    }
    
    function hideReviewer(){
      $("#box-check-comment").addClass('hide-box');
    }

    function showReviewer(readonly){
      readonly = readonly || false;
      $("#box-check-comment").removeClass('hide-box');
      $("#box-check-comment textarea").prop("disabled",readonly);
      $("#box-check-comment button").prop("disabled",readonly);
      if(readonly){
        $("input[name=reviewer_flag]").val("no");
      }
    }
    
    var bsave = $("#btn-save-evl");
    var bedit = $("#btn-edit-evl");
    var bcanc = $("#btn-cancel-evl");
    var bremv = $("#btn-remove-evl");
    var bchck = $("#btn-check-evl");
    
    //init
    hideBtn(bsave);
    hideBtn(bedit);
    hideBtn(bcanc);
    hideBtn(bremv);
    hideBtn(bchck);
    hideReviewer();
    if (state == 'evaluated') {
      showBtn(bedit);
      showBtn(bremv);
      if(callEvaluate.evaluateStateCheck=='yes'){
        showBtn(bchck);
      }
      disableForm();
      showReviewer(true);
    } else if (state == 'edit') {
      showBtn(bcanc);
      showBtn(bsave);
      enableForm();
      showReviewer(true);
    } else if (state == 'check') {
      showBtn(bcanc);
      showBtn(bsave);
      enableForm();
      showReviewer(false);
    } else if(state == 'disabled'){
      disableForm();
    } else {
      showBtn(bsave);
      enableForm();
    }
  },
  
  iCheckSetup: function(state){
    var oRad = $(".block-choice input:radio");
    var oChb = $(".block-choice input:checkbox");
    if(state == 'init'){
      try {
        oRad.iCheck('destroy');
        oChb.iCheck('destroy');
      } catch(e){}
      oRad.iCheck({
        handle: 'radio',
        radioClass: 'iradio_square-blue'
      });
      oChb.iCheck({
        handle: 'checkbox',
        checkboxClass: 'icheckbox_square-blue'
      });
    } else if(state == 'disable'){
      oRad.iCheck('disable');
      oChb.iCheck('disable');
    } else if(state == 'enable'){
      oRad.iCheck('enable');
      oChb.iCheck('enable');
    } else if(state == 'update'){
      oRad.iCheck('update');
      oChb.iCheck('update');
    } else {
      /* destroy */
      oRad.iCheck('destroy');
      oChb.iCheck('destroy');
    }
    $("#box-inprocessing").addClass('hide-block');
  },
  
  loadEvaluatedResult: function(){
    function setAsstResult(asst,toReplace) {
      var htm = appl.getHtmlTemplate("#template-asst-details");
      asst.forEach(function(a){
        var oq = $("#data-asst-id-" + a.question_id);
        
        if((oq.length > 0) && isDefined(a.detected_info)){
          if(!isBlank(a.detected_info.matched_sentenses)){
            a.detected_info.showToggle = true; 
          }
          oq.html(htm(a.detected_info));
        }
        
        if(toReplace){
          var qb = $("#data-question-id-" + a.question_id);
          if(qb.length > 0){
            var ox = $("input[data-value-name=\"" + a.result_txt.replace(/\"/g,"'") + "\"]",qb);
            if(ox.length > 0){
              ox.prop("checked",true);
            }
          }  
        }
      });
      
      $("button.btn-toggle-asst-result").off('click').on('click',function(){
        var o = $(this);
        var ob = $('i',o).toggleClass('fa-chevron-up fa-chevron-down');
        if(ob.hasClass('fa-chevron-up')){
          $("div.block-asst-sentences",o.parent()).removeClass('hide-block');
        } else {
          $("div.block-asst-sentences",o.parent()).addClass('hide-block');
        }
      });
      $("div.block-asst-sentences a").off('click').on('click',function(){
        var o = $(this);
        ap.seek(parseFloat(o.attr('data-ssec'))*1000);
      });
    }
    
    function setEvaluatedScore(scores) {
      if (isPresent(scores.evaluation_log_id)) {
        scores.result.forEach(function(sc){
          var o = $("#data-question-id-" + sc.question_id);
          var t = o.attr('data-choice-type');
          if(o.length > 0){
            sc.result.forEach(function(s){
              if((t == 'radio') || (t == 'checkbox')){
                var ox = $("input[data-value-name=\"" + s.title.replace(/\"/g,"'") + "\"]",o).prop("checked",true);
                if(ox.length < 0){
                  /* not found set by score */
                }
              } else if (t == 'combo'){
                $("select option[value=\"" + s.score + "\"]",o).prop("selected",true);
              } else if (t == 'numeric') {
                $("input[type=\"number\"]",o).val(s.score); 
              }
            });
            if(isNotNull(sc.comment) && (sc.comment.length > 0)){
              $("input.quest_comment",o).val(sc.comment);
              $(".block-quest-comment",o).removeClass('hide-comment');
            }
          }
        });
        setSummaryComment(scores.comment);
        setReviewer(scores.reviewer);
        setAttachment(scores.evaluation_log_id, scores.attachments);
      }
    }
    
    function setReviewer(rv){
      var o = $("#box-check-comment");
      if(rv.result.length <= 0){
        o.addClass('hide-box'); 
      } else {
        o.removeClass('hide-box');
        $("button.btn-check-correct",o).removeClass("btn-success");
        $("button.btn-check-wrong",o).removeClass("btn-danger");
        if(rv.result == "W"){
          $("button.btn-check-wrong",o).addClass("btn-danger"); 
        } else if(rv.result == "C"){
          $("button.btn-check-correct",o).addClass("btn-success");
        }
        $("#reviewer_comment").val(rv.comment);
      }
    }
    
    function checkAttachmentState(){
      $("#box-doc-attachment table tbody tr").each(function(){
        var o = $(this);
        var b = $(".btn-edit-atch",o);
        var d = $(".btn-download-atch",o);
        var url = Routes.list_evaluation_doc_attachments_path({ template_id: b.attr("data-template-id"), log_id: b.attr("data-log-id") });
        jQuery.getJSON(url,function(data){
          if(data.id <= 0){
            b.removeClass('btn-primary').addClass('btn-success');
            d.prop("disabled",true);
            $('span',b).html("New"); 
          } else {
            b.removeClass('btn-success').addClass('btn-primary');
            $('span',b).html("Edit");
            d.prop("disabled",false);
          }
        });
      });
    }
    
    function setAttachment(log_id, atchs){
      var htm = appl.getHtmlTemplate("#template-attachment-list");
      $(".box-doc-attachment").addClass("hide-box");
      $("#box-doc-attachment div").html("");
      $("#box-doc-attachment div").append(htm(atchs));
      $(".btn-edit-atch").off('click').on('click',function(){
        var o = $(this);
        var url = Routes.new_evaluation_doc_attachment_path() + "?template_id=" + o.attr("data-template-id") + "&log_id=" + log_id;
        var htm = appl.getHtmlTemplate("#template-attachment-dialog");
        bootbox.dialog({
          message: htm({ atchs: atchs, log_id: log_id, url: url }),
          title: "Document Attachment",
          size: "large",
          animate: false,
          onEscape: function(){
            checkAttachmentState();
          }
        }).init(function(){
          $("li#template_id_" + o.attr("data-template-id"),$(this)).addClass("active");
          $("li").off('click').on('click',function(){
            var p = $(this);
            $('li',p.closest('ul')).removeClass('active');
            p.addClass('active');
            var url = Routes.new_evaluation_doc_attachment_path() + "?template_id=" + p.attr("data-template-id") + "&log_id=" + p.attr("data-log-id");
            $("iframe#atch_form").attr("src",url);
          });
        });
      });
      $(".btn-download-atch").off('click').on('click',function(){
        var o = $(this);
        appl.fileDownloadWithFormat(function(filetype){
          return Routes.download_evaluation_doc_attachments_path({ format: filetype }) + "?template_id=" + o.attr("data-template-id") + "&log_id=" + log_id;
        },appl.cof.dialogFileType.evaluationAttachment);
      });
      // popup
      if(atchs !== undefined && atchs.length > 0){
        $(".box-doc-attachment").removeClass("hide-box");
        if(callEvaluate.requireAttachmentDialog){
          $(".btn-edit-atch:first").trigger('click');
          callEvaluate.requireCloseMsg = false;
        }
      }
      checkAttachmentState();
    }
    
    function setSummaryComment(cmm){
      var o = $("#evl_comment");
      if(cmm !== null){
        o.val(cmm);
      } else {
        o.val("");
      }
      $("#evl_comment").trigger('autosize.resize');
    }
    
    function getResult() {
      jQuery.get(Routes.evaluated_info_voice_log_path(gon.params.id),{
        form_id: callEvaluate.formId
        }, function(data){
        callEvaluate.setAgentField(data.agent,data.group, data.leaders);
        setAsstResult(data.asst,(data.evls === null));
        if(data.evls !== null){
          callEvaluate.evaluateStateCheck = 'no';
          if(data.review_enable){
            callEvaluate.evaluateStateCheck = 'yes';
          }
          callEvaluate.setFormState('evaluated');
          setEvaluatedScore(data.evls);
          callEvaluate.iCheckSetup('init');
          if(callEvaluate.requireCloseMsg){
            if(gon.evaluation.close_window == "confirm"){
              callEvaluate.closeWindow();
            } else if(gon.evaluation.close_window == "close"){
              setTimeout(function(){ window.close(); }, 1500);
            }
          }
        } else {
          callEvaluate.iCheckSetup('init');
        }
        if(!data.form_enable){
          callEvaluate.setFormState('disabled');
          callEvaluate.showMsg("No authority to change this evaluation result.");
        }
        callEvaluate.requireAttachmentDialog = false;
        callEvaluate.requireCloseMsg = false;
        try {
          fnShow.resize(); 
        } catch(e){}
        appl.dialog.hideWaiting();
      });
    }
    
    appl.dialog.showWaiting();
    setTimeout(getResult, 100);
  },
  
  hideAttachmentDialog: function(){
    bootbox.hideAll();
  },

  setAgentField: function(agent,group,leaders){
    
    function setAgentField(agent){
      $("#evl_usr_id").html("");
      if(isPresent(agent) && isNotNull(agent.id)){
        $("#evl_usr_id").html($('<option>',{ value: agent.id, text: agent.name, seleted: true }));
      }
      appl.autocomplete.usersSelect("#evl_usr_id");
    }
    
    function setGroupField(group){
      $("#evl_group_id").html("");
      if(isPresent(group) && isNotNull(group.id)){
        $("#evl_group_id").html($('<option>',{ value: group.id, text: group.name, selete: true }));
      }
      appl.autocomplete.groupsSelect("#evl_group_id");
    }
    
    function setLeaderFields(leaders){
      $("select.fd-group-leader").html("");
      if(isPresent(leaders)){
        leaders.forEach(function(l){
          var o = $("#group_leader_" + l.type);
          if((o.length > 0) && isNotNull(l.id)){
            o.html($('<option>',{ value: l.id, text: l.name, selete: true }));
          }
        });
      }
      
      $("select.fd-group-leader").each(function(){
        var o = $(this);
        appl.autocomplete.usersSelect("#" + o.attr("id"));
      });
    }
    
    function updateFields(p){
      jQuery.getJSON(Routes.check_agent_info_call_evaluation_index_path(), p, function(data){
        if(isPresent(data.group)){
          setGroupField(data.group); 
        }
        if(isPresent(data.leaders)){
          setLeaderFields(data.leaders);
        }
      });
    }
    
    function bindEvent(){
      $("#evl_usr_id").off('select2:select').on('select2:select',function(){
        var u_id = $(this).val();
        if(isNotBlank(u_id)){
          updateFields({ agent_id: u_id, target: ['group','leader'] });
        }
      });
      $("#evl_group_id").off('select2:select').on('select2:select',function(){
        var u_id = $("#evl_usr_id option:selected").val();
        var g_id = $(this).val();
        if(isNotBlank(g_id)){
          updateFields({ agent_id: u_id, group_id: g_id, target: ['leader'] });
        }
      });
    }
    
    setAgentField(agent);
    setGroupField(group);
    setLeaderFields(leaders);
    bindEvent();
  },
  
  closeWindow: function(){
    var opts = {
      title: "Close Window",
      message: "Do you want to close this window?",
      buttons: {
        close: {
          label: "Close",
          className: "btn-primary",
          callback: function(){
            window.close();
          }
        },        
        cancel: {
          label: "Cancel",
          className: "btn-default",
          callback: function(){}
        }
      }
    };
    bootbox.dialog(opts);
  },
  
  saveForm: function()
  {
    var err = false;
    var dsAns = [], dsAgent = {};
    
    function isRequiredComment(o){
      if(o.attr("data-require-comment") == "true"){
        if(!callEvaluate.useOnlySummaryComment){
          var m = $('input.quest_comment',o.closest('.block-question'));
          if(m.length > 0 && jQuery.trim(m.val()).length <= 0){
            var p = $('div.block-quest-comment',o.closest('.block-question'));
            p.removeClass('hide-comment');
            return true;
          }
        } else {
          var m1 = $("#evl_comment");
          if(jQuery.trim(m1.val()).length <= 0){
            $("#box-summary-comment").addClass('has-error');
            return true;
          }
        }
      }
      return false;
    }
    
    function getRadioButton(pa) {
      var o = $("input:radio:checked",pa);
      if (o.length > 0) {
        if(isRequiredComment(o)){
          return null;
        }
        return [{ score: o.val(), title: o.attr("data-value-name") }];
      }
      return null;
    }
    
    function getCombo(pa){
      var o = $("select option:selected",pa);
      if(o.val().length > 0){
        if(isRequiredComment(o)){
          return null;
        }
        return [{ score: o.val(), title: o.text() }];
      }
      return null;
    }
    
    function getCheckBox(pa) {
      function isDeductionScore(v){
        return (parseInt(v) < 0);
      }
      var ans = [];
      $("input:checkbox",pa).each(function(){
        var o = $(this);
        if(o.prop('checked')){
          if(isDeductionScore(o.val())){
            ans.push({ score: o.val(), title: o.attr("data-value-name"), deduction: 'checked' });
          } else {
            ans.push({ score: o.val(), title: o.attr("data-value-name") });
          }
          if(isRequiredComment(o)){
            return null;
          }
        } else {
          if(isDeductionScore(o.val())){
            ans.push({ score: o.val(), title: o.attr("data-value-name"), deduction: 'uncheck' });
          } else {
            // nothing
          }
        }
      });
      if(ans.length >= 0){
        return ans;
      }
      return null;
    }
    
    function getTextNumberic(pa) {
      var o = $("input",pa);
      if(o.val().length > 0){
        var v = parseInt(o.val());
        if((v >= 0) && (v <=parseInt(o.attr("max")))){
          return [{ score: parseInt(o.val()) }];
        }
      }
      return null;
    }
    
    function getComment(pa){
      var v = jQuery.trim($("input.quest_comment",pa).val());
      if(v.length > 0){
        return v;
      }
      return null;
    }
    
    function getAndValidate() {
      $("#box-summary-comment").removeClass('has-error');
      $("#box-evaluation-form .block-question-group").each(function(){
        var oa = $(this);
        $(".block-question",oa).each(function(){
          var ob = $(this);
          var ctype = ob.attr("data-choice-type");
          var revno = ob.attr("data-revision-no");
          var ans = null;
          if (ctype == "radio") {
            ans = getRadioButton(ob);
          } else if(ctype == "checkbox") {
            ans = getCheckBox(ob);
          } else if(ctype == "numeric") {
            ans = getTextNumberic(ob);
          } else if(ctype == "combo"){
            ans = getCombo(ob);
          }
          if (ans === null) {
            ob.addClass('has-noselect');
            err = true;
          } else {
            dsAns.push({ question_id: ob.attr("data-question-id"), revision_no: revno, result: ans, comment: getComment(ob) });
            ob.removeClass('has-noselect');
          }
        });
      });
    }
    
    function getAgentInfo() {
      var oa = $("#evl_usr_id option:selected");
      var ob = $("#evl_group_id option:selected");
      if (oa.length > 0 && ob.length > 0) {
        if (oa.val().length > 0 && ob.val().length > 0) {
          dsAgent = { agent_id: oa.val(), group_id: ob.val() };
          $("select.fd-group-leader").each(function(){
            var ol = $(this);
            var ols = $("option:selected", ol);
            if(ol.length > 0 && ols.length > 0 && ols.val().length > 0){
              dsAgent[ol.attr("data-leader-type") + "_id"] = ols.val();
            }
          });
        } else {
          err = true;
        }
      } else {
        err = true;
      }
    }
    
    function getSummaryComment(){
      return jQuery.trim($("#evl_comment").val());
    }
    
    function checkReviewer(){
      var rs = reviewerInfo();
      if(rs.result.length <= 0 && rs.update_by_reviewer == "yes"){
        err = true;
        appl.noty.error("Please choose check result.");
      }
    }
    
    function reviewerInfo(){
      var result = "";
      if($("#btn-check-wrong").hasClass("btn-danger")){
        result = "W";
      } else if($("#btn-check-correct").hasClass("btn-success")) {
        result = "C";
      }
      var comment = jQuery.trim($("#reviewer_comment").val());
      return { result: result, comment: comment, update_by_reviewer: $("input[name=reviewer_flag]").val() };
    }
    
    function saveResult(){
      appl.dialog.showWaiting();
      jQuery.post(Routes.evaluate_voice_log_path(gon.params.id),{
        authenticity_token: window._frmTk,
        evaluation_form: {
          form_id: callEvaluate.formId,
          form_revision_no: callEvaluate.formRevisionNo,
          agent_id: dsAgent.agent_id,
          group_id: dsAgent.group_id,
          supervisor_id: dsAgent.supervisor_id,
          chief_id: dsAgent.chief_id,
          criteria: dsAns,
          comment: getSummaryComment(),
          reviewer: reviewerInfo()
        },
        mode: 'evaluate'
      },function(data){
        if(data.updated === true){
          callEvaluate.requireAttachmentDialog = true;
          callEvaluate.requireCloseMsg = true;
          callEvaluate.loadForm();
        } else {
          appl.noty.error("Unable to save evaluation form. Please try again.");
        }
        appl.dialog.hideWaiting();
      });
    }
    
    getAndValidate();
    getAgentInfo();
    checkReviewer();
    if (!err) {
      saveResult();
    } else {
      appl.noty.error("Evaluation form is incomplete.");  
    }
  },
  
  remove: function()
  {
    function performDelete(){
      jQuery.get(Routes.remove_evaluation_voice_log_path(gon.params.id),{
        form_id: callEvaluate.formId
      },function(){
        appl.noty.info("Evaluation form has been deleted.");
        window.location.reload();
      });      
    }
    
    var opts = {
      title: "Delete Evaluation",
      message: "Are you sure to delete this evaluation?",
      buttons: {
        close: {
          label: "Delete",
          className: "btn-primary",
          callback: function(){
            performDelete();
          }
        },        
        cancel: {
          label: "Cancel",
          className: "btn-default",
          callback: function(){}
        }
      }
    };
    bootbox.dialog(opts);
  },
  
  setCurrentForm: function()
  {
    function hideForm() {
      $("#box-oper-info").css("visibility","hidden");
      $("#box-evaluation-form").css("visibility","hidden");
      $("#box-summary-comment").css("visibility","hidden");
      $("#box-more-info").css("visibility","hidden");
      $("#box-noform").css("display","block");
    }
    function showForm() {
      $("#box-oper-info").css("visibility","visible");
      $("#box-evaluation-form").css("visibility","visible");
      $("#box-summary-comment").css("visibility","visible");
      $("#box-more-info").css("visibility","visible");
      $("#box-noform").css("display","none");
      $("#box-inprocessing").addClass('hide-block');
    }
    var o = $("select[name=evaluation_form] option:selected");
    if (o.val() === undefined) {
      hideForm();
      callEvaluate.formId = 0;
    } else {
      showForm();
      callEvaluate.formId = parseInt(o.val());
    }
  },
  
  checkEvaluationResult: function(){
    callEvaluate.setFormState('check');
    $("input[name=reviewer_flag]").val("yes");
  },
    
  init: function()
  {
    function toggleCheckResultButton(state){
      if(state == "correct"){
        $("#btn-check-wrong").removeClass("btn-danger");
        $("#btn-check-correct").addClass("btn-success");
      } else if(state == "wrong"){
        $("#btn-check-correct").removeClass("btn-success");
        $("#btn-check-wrong").addClass("btn-danger");
      }
    }
    
    function setButtons() {
      $("select[name=evaluation_form]").on('change',function(){
        callEvaluate.setCurrentForm();
        callEvaluate.loadForm();
      });
      $("#btn-save-evl").off('click').on('click',function(){
        callEvaluate.saveForm();
      });
      $("#btn-edit-evl").off('click').on('click',function(){
        callEvaluate.setFormState('edit');
      });
      $("#btn-cancel-evl").off('click').on('click',function(){
        $("#evl_check_result").val("");
        callEvaluate.setFormState('evaluated');
      });
      $("#btn-remove-evl").off('click').on('click',function(){
        callEvaluate.remove();
      });      
      $("#btn-check-evl").off('click').on('click',function(){
        callEvaluate.checkEvaluationResult();  
      });
      $("#btn-check-correct").off('click').on('click',function(){
        toggleCheckResultButton('correct');
      });
      $("#btn-check-wrong").off('click').on('click',function(){
        toggleCheckResultButton('wrong');
      });
      $("#evl_comment").autosize();
      $("#evl_comment").on('change keypress keydown keyup paste',function(){
        var t = $(this).val();
        if((1200 - t.length) <= 0){
          $(this).val(t.substring(0, 1200));
          $("#fd-remain-txt").html("");
        } else {
          $("#fd-remain-txt").html(" (Remaining Characters:" + (1200 - t.length) + ")");
        }
      });
    }
    
    callEvaluate.setAgentField();
    callEvaluate.setCurrentForm();
    callEvaluate.loadForm();
    setButtons();
  }
};