//= require 'call_state'
//= require 'wslogger'
//= require 'datatable'
//= require 'rtplayer'
//= require 'desktop_notif'
//= require 'bootstrap-slider.min'
//= require 'bootstrap-multiselect'
//= require 'call_browser_evlform'

/* call message status */
var rtm = {
  callStatus: null,
  connect: function()
  {  
    function setCallStatus(){
      var config = {
        wsUrl: gon.settings.callstatus.ws_url,
        subscribe: {
          type: gon.settings.callstatus.type,
          destination: gon.settings.callstatus.dest
        },
        onCallStatusChange: function(data){
          if(['connected','disconnected','xfer'].includes(data.call_status))
          cbs.updateCallStatus(data);
        }
      };
      this.callStatus = new WebOpenMQ(config);
    }
    setCallStatus();
  }
};

var cbs = {
  INVERVAL_STATUS_TIMER: 1000,
  DELAY_DISCONNECTED: 3000,
  ds: null,
  oTable: null,
  filter: null,
  notif: null,
  currentMonitId: null,
  currentCall: null,
  countUser: 0,
  listUserIDs: [],
  counter: {
    logon: 0,
    connected: 0,
    disconnected: 0,
    max_duration: 0,
    average_duration: 0,
    inbound: 0,
    outbound: 0
  },
  css: {
    ulog: "txt-user-logged",
    unlog: "txt-user-notlogged",
    uall: "txt-user-logged txt-user-notlogged",
    cont: "txt-call-connected",
    dist: "txt-call-disconnected",
    call: "txt-call-connected txt-call-disconnected"
  },
  
  debug: function(o){
    console.log(o);  
  },
  
  clearFilter: function(){
    $("#cb-filter").val("");
  },
  
  loadData: function(group_id){
    var url = Routes.members_call_browser_index_path();
    var opts = {
      group_id: group_id 
    };
    if(isPresent(group_id) && isNotNull(group_id)){
      appl.cookies.set('call-monitor-groups',group_id.join("|"));
    }
    appl.dialog.showWaiting();
    cbs.clearFilter();
    jQuery.getJSON(url, opts, function(data){
      cbs.ds = data;
      if(isPresent(data.users)){
        cbs.countUser = data.users.length;
        cbs.listUserIDs = data.users.map(function(u){ return u.id; });
      } else {
        cbs.countUser = 0;
        cbs.ds.users = [];
      }
      cbs.updateView();
    });
  },
  
  updateView: function()
  {
    
    function rowEvent(){
      var dbclick = function(){
        appl.dialog.showWaiting();
        var o = $(this);
        if (!o.hasClass("bx-listenning")){
          cbs.stopMonitoring();
          cbs.currentMonitId = o.attr("data-userid");
          $("#cont-list table tbody tr").removeClass("bx-listenning");
          o.addClass("bx-listenning");
          $("#cur-listen").css('visibility','visible');
          $("#cur-fd-avartar").html(o.find(".bx-avatar").html());
          $("#cur-fd-opname").html(o.find(".fd-opname").html());
        } else {
          cbs.stopMonitoring();
          o.removeClass("bx-listenning");
          $("#cur-listen").css('visibility','hidden');
        }
        appl.dialog.hideWaiting();        
      };
      return dbclick;
    }
    
    function bindTableEvent(){
      var revt = rowEvent();
      $("#cont-list table tbody tr").off('dblclick').on('dblclick',revt);    
    }
    
    function drawDataTable(){
      function getHeight(){
        return $(window).height() - ($("#bx-header1").outerHeight() + $("#bx-detail1").outerHeight() + $("#bx-call-summary").height() + 95);
      }
      var htm_template = appl.getHtmlTemplate("#user-list-template");
      $("#cont-list").html(htm_template(cbs.ds));
      var opts = appl.dtTable.options.callBrowser({ "scrollY": getHeight() });
      cbs.oTable = $('#cont-list table').dataTable(opts);
      cbs.onreSize();
      htm_template = null;
    }
    
    $("#bx-call-summary").css('visibility','visible');
    drawDataTable();
    bindTableEvent();
    cbs.callStatusTimer();
    cbs.callCounterTimer();
    appl.dialog.hideWaiting();
  },
  
  showCallNotification: function(u)
  {
    function isConnected(u){
      return u.current_call.call_status == CallState.CONNECTED;
    }
    
    function makeMessage(u){
      var msg = "" + u.name + " is talking.";
      var ico_name = "outb";
      if (u.current_call.direction == "i") {
        ico_name = "inb";
      }
      return { message: msg, icon: ico_name };
    }
    
    if (isConnected(u)){
      var m = makeMessage(u);
      cbs.notif.showCallNotification(m.message, m.icon);
    }
  },
  
  /* update current call info from message */
  updateCallStatus: function(csts)
  {
    for(var i=0; i<cbs.countUser; i++){
      var u = cbs.ds.users[i];
      if (csts.agent_id == u.id){
        u.current_call = csts;
        u.is_active = true;
        if (isPresent(u.call_summary) && (u.current_call.call_status == CallState.CONNECTED)){
          if (u.current_call.direction == 'i') {
            u.call_summary.tt_inbound++;
          } else {
            u.call_summary.tt_outbound++;
          }
        }
        cbs.showCallNotification(u);
        break;
      }
    }
  },
  
  /* update summary call / counter */
  updateSummaryInfo: function()
  {
    $("#fd-tt-user").html(cbs.counter.logon);
    $("#fd-tt-idle").html(cbs.counter.logon - cbs.counter.connected);
    $("#fd-tt-talking").html(cbs.counter.connected);
    $("#fd-tt-inbound").html(cbs.counter.inbound);
    $("#fd-tt-outbound").html(cbs.counter.outbound);
  },
  
  /* update table for latest status */
  updateStatus: function(u)
  {
    function targetObjRow(id){
      return $("#user_" + id);
    }

    /*
    To start/stop playing target call
    */
    function callPlayer(cl){
      cbs.currentCall = cl;
      function isListenNotStarted(){
        return ((cl.call_status == CallState.CONNECTED) && !CbPlayer.isPlaying());
      }
      function isListenStopping(){
        return ((cl.call_status == CallState.DISCONNECTED) && CbPlayer.isPlaying());
      }
      if(isListenNotStarted()){
        cbs.debug("play starting");
        CbPlayer.listen({
          user_id: u.id,
          chn: u.current_call.channel_id,
          dev: u.current_call.device_id,
          sys: u.current_call.system_id,
          ext: u.current_call.extension,
          call_id: u.current_call.call_id
        });
      } else if(isListenStopping()) {
        CbPlayer.stop();
        cbs.currentCall = null;
      }
    }
    
    function durationCssCls(sec){
      var colors = gon.settings.duration_colors;
      var l = colors.length;
      for(var i=0; i<l; i++){
        var color = colors[i];
        if (sec >= color[0]){
          return color[1];
        }
      }
      return "";
    }
    
    function onlyTime(s) {
      if (isEmpty(s)) {
        return "";
      } else {
        return s.toString().split(" ")[1];
      }
    }
    
    var oU = targetObjRow(u.id);
    if (isPresent(oU)){
      
      var oTbl = cbs.oTable;
      var rObj = oU;
      var oCl = u.current_call || false;
      var rPos = null;
      try {
        rPos = oTbl.fnGetPosition(oU.get(0));
      } catch(e){}
      
      var fnUpdateField = function(vx, rx, cx) {
        oTbl.fnUpdate(vx, rx, cx, false, false);
      };
      
      if (isNotNull(rPos)){
        /* calling status */
        var fdc = rObj.find(".fd-callsts");
        if(u.is_active){
          fdc.removeClass(cbs.css.uall).addClass(cbs.css.ulog);
          fnUpdateField(gon.settings.const.userstatus.logged, rPos, 1);
        } else {
          fdc.removeClass(cbs.css.uall).addClass(cbs.css.unlog);
          fnUpdateField(gon.settings.const.userstatus.not_logged, rPos, 1);
        }
        
        /* call summary */
        if(u.is_active && isPresent(u.call_summary)){
          var csum = u.call_summary;
          fnUpdateField(csum.tt_inbound,rPos,11);
          if (csum.tt_inbound > 0) {
            fnUpdateField(csum.mx_duration_inbound,rPos,12);
            fnUpdateField(csum.tt_duration_inbound,rPos,13);
            fnUpdateField(csum.avg_duration_inbound,rPos,14);        
          }
          fnUpdateField(csum.tt_outbound,rPos,15);
          if (csum.tt_outbound > 0) {
            fnUpdateField(csum.mx_duration_outbound,rPos,16);
            fnUpdateField(csum.tt_duration_outbound,rPos,17);
            fnUpdateField(csum.avg_duration_outbound,rPos,18);        
          }
          cbs.counter.inbound = cbs.counter.inbound + parseInt(csum.tt_inbound);
          cbs.counter.outbound = cbs.counter.outbound + parseInt(csum.tt_outbound);
        }
        
        /* update last call status */
        if(oCl !== false){
          var defaultInfo = function(){
            return {
              ok: false,
              phone: "",
              ani: "",
              dnis: "",
              stime: "",
              sts: gon.settings.const.userstatus.logged,
              dir: "",
              dircls: "",
              dur: "",
              dur_fg: "",
              acls: "",
              rcls: "",
              extension: ""
            };
          };
          
          var di = defaultInfo();
          
          if (oCl.call_status == CallState.CONNECTED){
            di.ok = true;
            di.sts = gon.settings.const.callstatus.connected;
            di.acls = cbs.css.cont;
          } else if(oCl.call_status == CallState.DISCONNECTED){
            var diff_ms = moment.duration(moment().diff(moment(oCl.start_time).add(oCl.duration_sec,'seconds')));
            if (diff_ms <= cbs.DELAY_DISCONNECTED) {
              di.ok = true;
              di.sts = gon.settings.const.callstatus.disconnected;
              di.acls = cbs.css.dist;
            }
          }
          
          if (di.ok) {
            di.stime = oCl.start_time;
            di.ani = oCl.ani;
            di.dnis = oCl.dnis;
            di.extension = oCl.extension;
            di.sts = oCl.sts_name;
            if (oCl.direction == CallDirection.IN) {
              di.dir = gon.settings.const.cdirname.i;
              di.dircls = "text-inbound";
              di.phone = oCl.ani;
            } else if(oCl.direction == CallDirection.OUT) {
              di.dir = gon.settings.const.cdirname.o;
              di.dircls = "text-outbound";
              di.phone = oCl.dnis;
            }
            di.dur = moment.utc(appl.sToms(oCl.duration_sec)).format('HH:mm:ss');
            di.dur_fg = durationCssCls(parseInt(oCl.duration_sec));
          }
          
          if(di.extension.length > 0){
            fnUpdateField(di.extension, rPos, 5); 
          }
          
          fnUpdateField(onlyTime(di.stime), rPos, 6);
          fnUpdateField(di.ani, rPos, 7);
          fnUpdateField(di.dnis, rPos, 8);
          fnUpdateField(di.dur, rPos, 10);
          fnUpdateField(di.dir, rPos, 9);
          fnUpdateField(di.sts, rPos, 1);
          
          rObj.find(".fd-duration").css("color",di.dur_fg);
          rObj.find(".fd-dirname").removeClass("text-inbound text-outbound").addClass(di.dircls);
          rObj.find(".fd-callsts").removeClass(cbs.css.call).addClass(di.acls);
                    
          /* update for selected */
          if (cbs.currentMonitId == u.id) {
            $("#cur-fd-calldir").html(di.dir).removeClass("text-inbound text-outbound").addClass(di.dircls);
            $("#cur-fd-phno").html(di.phone);
            $("#cur-fd-callsts").html(di.sts).removeClass(cbs.css.call).addClass(di.acls);
            $("#cur-fd-duration").html(di.dur).css("color",di.dur_fg);
            $("#cur-fd-extno").html(di.extension);
            $("#cur-fd-stime").html(onlyTime(di.stime));
            callPlayer(oCl);
          } else if (cbs.currentMonitId === null) {
            $("#cur-fd-calldir").html("");
            $("#cur-fd-phno").html("");
            $("#cur-fd-callsts").html("");
            $("#cur-fd-duration").html("");
            $("#cur-fd-extno").html("");
            $("#cur-fd-stime").html("");
          }
          
        } /* oCl */
      } /* rPos */
    } /* oU */
  },
  
  callStatusTimer: function(){
    
    function gotCurrentCall(cl){
      return ((cl !== null) && (cl !== false));
    }
    
    function callDurationSec(stime){
      return moment.duration((moment().diff(moment(stime)))).asSeconds();
    }
    
    function resetCounter() {
      cbs.counter.connected = 0;
      cbs.counter.disconnected = 0;
      cbs.counter.logon = 0;
      cbs.counter.inbound = 0;
      cbs.counter.outbound = 0;    
    }
    
    function updateCounter() {
      for(var i=0; i<cbs.countUser; i++){
        var cl = cbs.ds.users[i].current_call;
        var ur = cbs.ds.users[i];
        if (ur.is_active) {
          cbs.counter.logon++;
        }
        if (gotCurrentCall(cl)){
          if (cl.call_status == CallState.CONNECTED) {
            cl.duration_sec = callDurationSec(cl.start_time);
            cbs.counter.connected++;
          } else {
            cbs.counter.disconnected++;
          }
        }
        if (ur.is_active) {
          cbs.updateStatus(ur);
        }
      }
      try {
        // adjust column and fix scoll change
        var oTop = $("#bx-chn-list div.dataTables_scrollBody").scrollTop();
        cbs.oTable.fnAdjustColumnSizing();
        $("#bx-chn-list div.dataTables_scrollBody").scrollTop(oTop);
      } catch(e){}
    }
    
    resetCounter();    
    updateCounter();
    cbs.updateSummaryInfo();
    setTimeout(function(){cbs.callStatusTimer();},cbs.INVERVAL_STATUS_TIMER);
  },
  
  callCounterTimer: function(a)
  {
    var b = a || 0;
    if(isPresent(cbs.ds.users) && (b < cbs.ds.users.length)){
      $("#cb_group").multiselect('disable');
      $("#btn-search").attr('disabled','disabled');
      var u = cbs.ds.users[b];
      if (u.is_active) {
        var url = Routes.summary_data_call_browser_index_path();
        jQuery.getJSON(url,{ user_id: u.id },function(result){
          cbs.ds.users[b].call_summary = result.call_summary;
          cbs.callCounterTimer(b+1);
        });
      } else {
        //next
        cbs.callCounterTimer(b+1);
      }
    } else {
      $("#btn-search").removeAttr('disabled');
      $("#cb_group").multiselect('enable');
      setTimeout(function(){
        cbs.callCounterTimer();
      },1000*60*10);
    }
  },
  
  onreSize: function()
  {
    var wh = $(window).height();
    if (isSet(cbs.oTable)) {
      var bfh = $("#bx-header1").outerHeight() + $("#bx-call-summary").outerHeight() + $(".dataTables_scrollHeadInner").outerHeight() + 30;
      var afh = $("#bx-detail1").outerHeight();
      $('.dataTables_scrollBody').css('height',wh - (bfh + afh));
    }
  },
  
  deskTopNotif: function(){
    cbs.notif = new desktopNotification();
  },
  
  isMonitoring: function(){
    return (cbs.currentMonitId !== null);
  },
  
  isCallConnected: function(){
    return (cbs.currentCall && cbs.currentCall.call_status == CallState.CONNECTED);
  },
  
  isMonitoringAndConnected: function(){
    return cbs.isMonitoring() && cbs.isCallConnected();
  },
  
  doEvaluate: function(){
    var cl = cbs.currentCall;
    var parm = {
      call_id: cl.call_id,
      system_id: cl.system_id,
      device_id: cl.device_id,
      channel_id: cl.channel_id,
      start_time: cl.start_time,
      ani: cl.ani,
      dnis: cl.dnis,
      direction: cl.direction
    };
    jQuery.getJSON(Routes.get_voice_log_call_browser_index_path(),parm,function(data){
      if (data.found) {
        callEvaluate.voiceId = data.id;
        callEvaluate.init();
      }
    });
  },
  
  stopMonitoring: function(){
    CbPlayer.stop();
    cbs.currentMonitId = null;  
  },
  
  recheckStatusFromWeb: function(){
    function tryCheck(){
      if(cbs.countUser > 0){
        var t = moment().format("X");
        jQuery.post(Routes.call_status_call_browser_index_path(),jQuery.extend({ t: t, uids: cbs.listUserIDs },appl.defaultPostParams()),function(data){
          data.forEach(function(csts){
            for(var i=0; i<cbs.countUser; i++){
              var u = cbs.ds.users[i];
              if (csts.agent_id == u.id){
                u.current_call = csts;
                u.is_active = true;
                break;
              }
            }
          });
          setTimeout(function(){ cbs.recheckStatusFromWeb(); },3000);
        });
      } else {
        setTimeout(function(){ cbs.recheckStatusFromWeb(); },5000);
      }
    }
    tryCheck();
  },
  
  init: function()
  {
    
    function setEvents()
    {
      /* group select and search */
      try {
        var groups = appl.cookies.get('call-monitor-groups').split("|");
        $("#cb_group option").each(function(){
          var og = $(this);
          if(groups.includes(og.val())){
            og.prop("selected",true); 
          }
        });     
      } catch(e){}
      $("#cb_group").multiselect({
        includeSelectAllOption: false,
        maxHeight: 250,
        buttonWidth: 200
      });
      
      $("#btn-search").off('click').on('click',function(){
        var groups = $("#cb_group").val();
        if (isPresent(groups)) {
          cbs.stopMonitoring();
          cbs.loadData(groups);
        }
      });
      
      /* audio volume slider */
      $("#btn-volume").off('click').on('click',function(){
        var o = $("#slider-volume");
        if (o.css("display") == "none") {
          o.css("display","inline-block");
        } else {
          o.css("display","none");
        }
      });
      
      $("#vol-input-slider").slider({
        value: CbPlayer.volume.current()
      }).on('slideStop',function(e){
        CbPlayer.volume.set(e.value);
      });
      
      /* list of call */
      $("button#btn-calllist").off('click').on('click',function(){
        appl.openUrl(Routes.call_histories_path({u: cbs.currentMonitId}));
      });
      
      /* row filter */
      $("#cb-filter").on('keyup change',function(){
        if (cbs.oTable !== null){
          cbs.oTable.fnFilter($(this).val());
        }
      });
      
      /* evaluate */
      //$("#btn-evaluate").off('click').on('click',function(){
      //  if (cbs.isMonitoringAndConnected()) {
      //    $("#box-evaluation").css("display","block");
      //    $("#box-evaluation-inner").css("display","block");
      //    cbs.onreSize();
      //    cbs.doEvaluate();
      //    $("#btn-canc-evaluate").css("display","inline-block");
      //    $("#btn-evaluate").css("display","none");          
      //  } else {
      //    appl.noty.info("No call for evaluate."); 
      //  }
      //});
      $("#btn-canc-evaluate").off('click').on('click',function(){
        bootbox.confirm("Are you sure to close this form?",function(rs){
          if(rs){
            $("#box-evaluation").css("display","none");
            $("#box-evaluation-inner").css("display","none");
            $("#btn-canc-evaluate").css("display","none");
            $("#btn-evaluate").css("display","inline-block");
          }
        });
      });
      
      /* settings */
       $(".showhide_col").off('click').on('click',function(){
        var o = $(this);
        var cidx = parseInt(o.attr("data-col-index"));
        var t = cbs.oTable;
        var bVis = t.fnSettings().aoColumns[cidx].bVisible;
        t.fnSetColumnVis( cidx, bVis ? false : true );
      });

      /* page resize */
      cbs.onreSize();
      $(window).resize(function() { cbs.onreSize(); });
    }
    
    function setConfig() {
      cbs.DELAY_DISCONNECTED = gon.settings.hangup_delay * 1000;
    }
    
    function setConnection() {
      rtm.connect();
      cbs.deskTopNotif();
    }
    
    function autoLoadGroup(){
      setTimeout(function(){
        var groups = $("#cb_group").val();
        if (isPresent(groups)) {
          cbs.loadData(groups);
        }
      },1000);
    }
    
    appl.dialog.showWaiting();
    setConfig();
    setEvents();
    setConnection();
    appl.dialog.hideWaiting();
    autoLoadGroup();
    setTimeout(function(){ cbs.recheckStatusFromWeb(); },3000);
  }
};

jQuery.ajaxSetup({ cache: false });
jQuery(document).on('ready page:load',function(){ cbs.init(); });