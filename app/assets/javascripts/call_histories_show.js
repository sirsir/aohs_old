//= require 'svg'
//= require 'audioplayer'
//= require 'call_infos'
//= require 'charts'
//= require 'jquery.highlight'
//= require 'base_form'

var fnShow = {
  dsCall: null,
  _cknAutoScrollTran: "trans-auto-scroll",
  _cknShowHidePanelLeft: "showhide-panel-left",
  
  setCallInfo: function(){
    function loadDataFromJson(){
      var data = jQuery.parseJSON($("#voicelog-data").html());
      fnShow.dsCall = data;
    }
    
    function renderView(){
      var htmTb = appl.hbsTemplate("template-callinf-topbar");
      $("div#block-callinf-topbar").html(htmTb(fnShow.dsCall));
      var htmCh = appl.hbsTemplate("template-callinf-channels");
      $("td#block-channel-list").html(htmCh(fnShow.dsCall.audio_channels));
      var htmCl = appl.hbsTemplate("template-releated-calllist");
      $("td#block-releated-callslist div").html(htmCl(fnShow.dsCall.releated_calls));
      if(fnShow.dsCall.releated_calls.length <= 0){
        $("td#block-releated-callslist").addClass("collapse-callist"); 
      }
    }
    
    appl.dialog.showWaiting();
    loadDataFromJson();
    renderView();
    callInfo.showAll(fnShow.dsCall.id);
  },
  
  hideWaveForm: function(){
    $("td#block-channel-list").addClass('hide-cell').html("");
  },
  
  setAudioPlayer: function(){
    function loadAudioFile(){
      var opts = {
        showWaveForm: !gon.audioplayer.waveform.disabled
      };
      ap.setAudioUrl(fnShow.dsCall.temp_file_url,opts);
      ap.setAttrs(fnShow.dsCall.id);
      if(opts.showWaveForm == true){
        ap.loadWaveForm(fnShow.dsCall.id);
      } else {
        fnShow.hideWaveForm();
      }
      if (isPresent(gon.params.t) && !isBlank(gon.params.t)) {
        ap.playAt(gon.params.t);
      }
    }
    
    setTimeout(function(){
      loadAudioFile();
    },100);
  },

  resize: function(){
    var fnResize = function(){
      var xh = $(window).height();
      var ph = $(".panel-call-info").outerHeight();
      var th = xh - (ph + 20);
      $("#cdt-container").height(th);
      th = th - 10;
      $("#td-cdt-1 .block-scroll").height(th - ($("#btn-hide-cdt1").outerHeight()+10));
      var ts1 = $("#box-trans-option").outerHeight();
      var ts2 = $("#box-detected-info").outerHeight();
      $("#td-cdt-2 .block-scroll").height(th - (ts1+ts2));
      var fh = $("#td-cdt-3 .block-fixed-top");
      if(fh.length >= 0){
        fh = fh.outerHeight() + $("#td-cdt-3 .box-tabs").outerHeight();
      } else {
        fh = 0;
      }
      $("#td-cdt-3 .block-scroll").height(th-fh);
    };
    
    $(window).resize(fnResize);
    fnResize();
  },
  
  eMailDialog: function()
  {
    var cPos = 0;
    
    var isInputComplete = function(em,subj,msg) {
      var t = ".ml-dialog";
      var o = $(t + " select[name=ml-sender]");
      o.closest(".form-group").removeClass("has-error").find(".help-block").remove();
      
      var p = $(t + " input[name=ml-subject]");
      p.closest(".form-group").removeClass("has-error").find(".help-block").remove();

      var q = $(t + " textarea[name=ml-message]");
      q.closest(".form-group").removeClass("has-error").find(".help-block").remove();
      
      if (isAryEmpty(em)) {
        o.closest(".form-group").addClass("has-error");
        o.next().append($("<span>",{ class: 'help-block', text: 'e-mail is required.'}));
        return false;
      } else if (isBlank(subj)) {
        p.closest(".form-group").addClass("has-error");
        p.after($("<span>",{ class: 'help-block', text: 'subject is required.'}));
        return false;
      } else if (isBlank(msg)) {
        q.closest(".form-group").addClass("has-error");
        q.after($("<span>",{ class: 'help-block', text: 'message is required.'}));
        return false;
      }
      return true;
    };
    
    var fnGetInput = function(){
      var o = {}, t = ".ml-dialog";
      o.em = appl.getSelectValues(t + " select[name=ml-sender]");
      o.msg = getVal($(t + " textarea[name=ml-message]").val());
      o.subj = getVal($(t + " input[name=ml-subject]").val());
      o.attach_file = getVal($(t + " #ml-attached-file option:selected").val());
      return o;
    };
    
    var dOpts = {
      title: "Send E-mail",
      message: appl.getHTML("#mail-dialog-template"),
      className: 'ml-dialog',
      buttons: {
        ok: {
          label: "Send",
          className: "btn-primary",
          callback: function()
          {
            var o = fnGetInput();
            var p = {
                to: o.em,
                subj: o.subj,
                msg: o.msg,
                id: gon.params.id,
                stsec: cPos,
                attach_file: o.attach_file,
                authenticity_token: appl.postKeyString()
            };
            if (isInputComplete(o.em,o.subj,o.msg)) {
              jQuery.post(Routes.send_mail_voice_logs_path(),p,function(data){
                appl.noty.success("E-mail has been sent.");
              });
            } else {
              return false;
            }
          }
        },
        cancel: {
          label: "Cancel",
          className: "btn-default",
          callback: function(){ }
        }
      }
    };
    
    var fnSend = function(){
      cPos = ap.currentPosition();
      bootbox.dialog(dOpts);
      appl.autocomplete.mailerSelect("select[name=ml-sender]");
    };
    
    $("#btn-send-mail").on("click",fnSend);
  },
  
  _togglePanel: function(){
    function initTab() {
      var etab = $(".box-tabs [data-pnl='pnl-evaluate']");
      if (gon.params.qa == "true" && etab.length > 0) {
        etab.trigger("click");
      } else {
        $(".box-tabs .tb-tab:first").trigger('click');
      }
    }
    // left panel
    $(".cdt-group-info h4").on('click',function(){
      var o = $(this);
      var i = o.find("i");
      i.toggleClass('fa-angle-down fa-angle-right');
      if(i.hasClass('fa-angle-down')){
        o.parent().find('.box-lft').css("display","block");
      } else {
        o.parent().find('.box-lft').css("display","none");
      }
    });
    // tabs
    $(".box-tabs .tb-tab").on('click',function(){
      var p = $(this).attr("data-pnl");
      $(".tb-pnl").css("display","none");
      $("#" + p).css("display","block");
      $(".tb-tab").removeClass('tab-selected');
      $(this).addClass('tab-selected');
    });
    initTab();
    
    $("#btn-hide-cdt1").on('click',function(){
      var o = $(this);
      var op = o.closest('td');
      $('i',o).toggleClass('fa-chevron-left fa-chevron-right');
      o.closest('td').toggleClass('show-panel hide-panel');
      if(op.hasClass('hide-panel')){
        appl.cookies.set(fnShow._cknShowHidePanelLeft, true);
      } else {
        appl.cookies.set(fnShow._cknShowHidePanelLeft, false);
      }
    });
    
    if(appl.cookies.get(fnShow._cknShowHidePanelLeft) !== null){
      if(appl.cookies.get(fnShow._cknShowHidePanelLeft) == "true"){
        $('i',$("#btn-hide-cdt1")).toggleClass('fa-chevron-left fa-chevron-right');
        $("#btn-hide-cdt1").closest('td').addClass('hide-panel');
      }
    }
  },
  
  _resizablePanel: function(){

  },
  
  _setEvents: function(){
    function autoScrollTranscription(){
      if(appl.cookies.get(fnShow._cknAutoScrollTran) !== null){
        if(appl.cookies.get(fnShow._cknAutoScrollTran) == "true"){
          $("#btn-auto-scroll i").removeClass('fa-square-o').addClass('fa-check-square-o');
          $("#btn-auto-scroll").attr("data-auto-scroll","true");
        } else {
          $("#btn-auto-scroll i").addClass('fa-square-o').removeClass('fa-check-square-o');
          $("#btn-auto-scroll").attr("data-auto-scroll","false");
        }
      }
      $("#btn-auto-scroll").on('click',function(){
        var o = $(this);
        $('i',o).toggleClass('fa-check-square-o fa-square-o');
        if($('i',o).hasClass('fa-square-o')){
          o.attr("data-auto-scroll","false");
          appl.cookies.set(fnShow._cknAutoScrollTran, false);
        } else {
          o.attr("data-auto-scroll","true");
          appl.cookies.set(fnShow._cknAutoScrollTran, true);
        }
      });
    }
    
    $("button#btn-showhide-addinfo").on('click',function(){
      $('i',this).toggleClass('fa-chevron-down fa-chevron-up');
      $("#box-additional-info > div").toggleClass('hide-block');
      fnShow.resize();
    });    
    
    $("div#tab-ana-result").on('click',function(){
      //var o = $(this);
      callInfo.__showAnaResult();
    });
    
    autoScrollTranscription();
  },
  
  init: function(){
    jQuery.ajaxSetup({
      // Disable caching of AJAX responses
      cache: false
    });
    //fnShow._resizablePanel();
    fnShow.setCallInfo();
    fnShow.setAudioPlayer();
    fnShow.eMailDialog();
    fnShow._togglePanel();
    fnShow._setEvents();
    fnShow.resize();
  }
};
 
jQuery(document).on('ready page:load',function(){ fnShow.init(); });
