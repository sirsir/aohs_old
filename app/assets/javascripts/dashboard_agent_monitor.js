//= require 'charts'
//= require 'd3-timeline'
//= require 'jstree.min'
//= require 'd3-tip.min'
//= require 'pikaday'

var das = {
  dasDate: moment(),
  dasDateDb: "",
  intervalUpdateSec: 300,
  currentNode: null,
  autoRefreshDas: false,
  rHeight: 150,
  tlWidth: 250,
  tlHeight: 15,
  tlHeight2: 100,
  _updateOvSum: function(ob_n,dsum){
    $(ob_n + " .ds-tt-call").html(appl.fmt.numberFmt(dsum.total_call));
    $(ob_n + " .ds-tt-inb").html(appl.fmt.numberFmt(dsum.total_inbound));
    $(ob_n + " .ds-tt-oub").html(appl.fmt.numberFmt(dsum.total_outbound));
    $(ob_n + " .ds-max-dur").html(appl.fmt.secToHMS(dsum.max_duration).clock);
    $(ob_n + " .ds-avg-dur").html(appl.fmt.secToHMS(dsum.avg_duration).clock);
    $(ob_n + " .ds-tt-usr").html(appl.fmt.numberFmt(dsum.total_users));
  },
  _drawCallByHr: function(ob_n,data){
    var chart = c3.generate({
      bindto: ob_n + " .chart-call-by-hr",
      size: { height: das.rHeight },
      data: {
        x: 'hour',
        columns: [data.hours, data.ttinb, data.ttoutb],
        groups: [["Inbound","Outbound"]],
        type: 'bar',
        colors: {
         inbound: appl.cof.color.inbound,
         outbound: appl.cof.color.outbound
        }  
      },
      axis: {
        y: { show: false },
        x: { type: 'category', tick: { culling: {max: 8 }, rotate: -90, multiline: false }, height: 40 }
      }
    });
  },
  _drawCallDurByHr: function(ob_n,data){
    //var chart = c3.generate({
    //  bindto: ob_n + " .chart-calldur-by-hr",
    //  size: { height: 150 },
    //  data: {
    //    x: 'hour',
    //    columns: [
    //      data.hours,
    //      data.ttinb_dur,
    //      data.ttoutb_dur,
    //    ],
    //    groups: [["Inbound","Outbound"]],
    //    type: 'bar',
    //    colors: {
    //     inbound: appl.cof.color.inbound,
    //     outbound: appl.cof.color.outbound
    //    }  
    //  },
    //  axis: {
    //    y: { show: false },
    //    x: { type: 'category', tick: { culling: {max: 6 }, rotate: -90, multiline: false }, height: 40 }
    //  }
    //});
  },
  _drawCallByDRange: function(ob_n,data){
    var chart = c3.generate({
      bindto: ob_n + " .chart-call-by-dur",
      size: { height: 150 },
      data: {
        x: 'range',
        columns: [
          data.ranges,
          data.inb,
          data.outb,
        ],
        groups: [["Inbound","Outbound"]],
        type: 'bar',
        colors: {
         inbound: appl.cof.color.inbound,
         outbound: appl.cof.color.outbound
        }  
      },
      axis: {
        y: { show: false },
        x: { type: 'category', tick: { rotate: 45, multiline: false }, height: 40 }
      }
    });
  },
  
  _drawAnaInfo: function(ob_n,data){

    var cclass = data.cclass;
    var chart = c3.generate({
      bindto: ob_n + " .chart-ana-class",
      size: { height: 150 },
      data: {
        columns: [
          cclass.result
        ],
        type: 'bar'
      },
      axis: {
        y: { show: false },
        x: { type: 'category', categories: cclass.list ,tick: { rotate: 45, multiline: false }, height: 50 }
      },
      legend: {
        show: false
      }
    });
    
    var reason = data.reason;
    var chart = c3.generate({
      bindto: ob_n + " .chart-ana-reason",
      size: { height: 150 },
      data: {
        columns: [
          reason.result
        ],
        type: 'bar'
      },
      axis: {
        y: { show: false },
        x: { type: 'category', categories: reason.list ,tick: { rotate: 45, multiline: false }, height: 50 }
      },
      legend: {
        show: false
      }
    });

    var asst = data.asst;
    var chart = c3.generate({
      bindto: ob_n + " .chart-ana-asst",
      size: { height: 150 },
      data: {
        columns: [
          reason.result
        ],
        type: 'bar'
      },
      axis: {
        y: { show: false },
        x: { type: 'category', categories: asst.list ,tick: { rotate: 45, multiline: false }, height: 50 }
      },
      legend: {
        show: false
      }
    });
    
    var csat = data.csat;
    var chart = c3.generate({
      bindto: ob_n + " .chart-ana-csat",
      size: { height: 150 },
      data: {
        columns: csat.result,
        type: 'donut',
        colors: {
          "satisfied": "#00CD66",
          "unsatisfied": "#CCCCCC"
        }
      },
      donut: {
        label: {
          show: false
        }
      },
      legend: {
        show: true
      }
    });

    var fcr = data.fcr;
    var chart = c3.generate({
      bindto: ob_n + " .chart-ana-fcr",
      size: { height: 150 },
      data: {
        columns: fcr.result,
        type: 'donut',
        colors: {
          "FCR": "#1E90FF",
          "Non-FCR": "#FFD700"
        }
      },
      donut: {
        label: {
          show: false
        }
      },
      legend: {
        show: true
      }
    });
    
  },
  
  _updateTblGrpsSummary: function(data){
    var htm_tempate = appl.getHtmlTemplate("#tbl-groups-template");
    var htm = htm_tempate(data);
    $("#tbl-groups-summary").html(htm);
  },
  _updateTblUsrsSummary: function(data){
    var htm_tempate = appl.getHtmlTemplate("#tbl-users-template");
    var htm = htm_tempate(data);
    $("#tbl-users-summary").html(htm);
  },
  _updateTblRepeatDialed: function(data){
    var htm_tempate = appl.getHtmlTemplate("#tbl-repeated-dialed-template");
    var htm = htm_tempate(data);
    $("#tbl-repeat-dialed").html(htm);
  },
  _updateTblTopKeyword: function(ob_n,data){
    var htm_tempate = appl.getHtmlTemplate("#tbl-top-keyword-template");
    var htm = htm_tempate(data);
    $(ob_n + " .tbl-top-keyword").html(htm);
  },
  _updateUserInfo: function(data){
    $("#fl-usr-name").html(data.name);
    $("#fl-usr-avatar").find("img").attr("src",Routes.avatar_user_path({ id: data.id }));
    $("#fl-usr-role").html(" (" + data.role_name + ")");
    $("#fl-usr-emid").html(data.employee_id);
  },
  _updateGroupInfo: function(data){
    $("#fl-grp-name").html(data.name);
    $("#fl-lea-role").html(data.leader_name);
  },
  _drawTimeLine: function(id){
    appl.dialog.showWaiting();
    var url = Routes.das_timeline_dashboard_index_path();
    jQuery.get(url,{id: id, d: das.dasDateDb, qt: 'group'},function(data){
      appl.dialog.hideWaiting();
      var l = data.users.length;
      for(var i=0; i<l; i++){
        var ds = data.users[i];
        var ob_id = "#timeline-cl-" + ds.user_id;
        var tl = d3.timeline()
          .margin({left: 0, right: 0, top: 0, bottom: 0})
          .showTimeAxis()
          .height(das.tlHeight)
          .click(function(d, i, da){ appl.openUrl(Routes.call_history_path(d.id)); })
          .mouseover(function(d,i,da){
            //console.log("m over");
            //console.log(i);
          })
          .mouseout(function(d,i,da){
            //console.log("m out");
            //console.log(da);
          })
          .beginning(data.beginning_time_i)
          .ending(data.ending_time_i)
        var svg = d3.select(ob_id).append('svg')
          .attr("width", das.tlWidth)
          .datum([ds]).call(tl);
      }
      // clear
      data.users = null;
    });
  },
  _drawUserTimeLine: function(id){
    appl.dialog.showWaiting();
    var url = Routes.das_timeline_dashboard_index_path();
    jQuery.get(url,{id: id, d: das.dasDateDb, qt: 'user'},function(data){
      var ds = data.users[0];
      var wh = $("#das-all").width() - 10;
      var ob_id = "#timeline-cl-pers";
      var tl = d3.timeline()
        .width(wh)
        .height(das.tlHeight2)
        .rotateTicks(45)
        .click(function(d, i, da){ appl.openUrl(Routes.call_history_path(d.id)); })
        .beginning(data.beginning_time_i)
        .ending(data.ending_time_i)
      d3.select(ob_id).selectAll('svg').remove();
      var svg = d3.select(ob_id)
        .append('svg')
        .attr("width", wh)
        .datum([ds]).call(tl);
      data.users = null;
      appl.dialog.hideWaiting();
    });
  },
  displayDasAll: function(nd){
    function updateView(){
      jQuery.get(Routes.das_data_dashboard_index_path(),{
        q: 'all',
        d: das.dasDateDb
      },function(data){
        var ob_n = "#das-all";
        das._updateOvSum(ob_n,data.ds.summary);
        das._drawCallByHr(ob_n,data.chart.call_by_hrs);
        das._drawCallDurByHr(ob_n,data.chart.call_by_hrs);
        das._drawCallByDRange(ob_n,data.chart.call_by_rngs);
        das._updateTblRepeatDialed(data.table.top_dialed_out);
        //das._updateTblTopKeyword(ob_n,data.table.top_keyword);
        appl.dialog.hideWaiting();
      });
    }
    $("#das-all").css("display","initial");
    updateView();
  },
  displayDasGrps: function(nd){
    function updateView(){
      jQuery.get(Routes.das_data_dashboard_index_path(),{
        q: 'groups',
        d: das.dasDateDb
      },function(data){
        var ob_n = "#das-groups";
        das._updateOvSum(ob_n,data.ds.summary);
        das._drawCallByHr(ob_n,data.chart.call_by_hrs);
        das._drawCallDurByHr(ob_n,data.chart.call_by_hrs);
        das._drawCallByDRange(ob_n,data.chart.call_by_rngs);
        das._updateTblGrpsSummary({ds_groups: data.table.group_summary});
        appl.dialog.hideWaiting();
      });
    }
    $("#das-groups").css("display","initial");
    updateView();
  },
  displayDasGrp: function(nd){
    function updateView(){
      var id = nd.id.replace("group-","")
      jQuery.get(Routes.das_data_dashboard_index_path(),{
        q: 'group',
        d: das.dasDateDb,
        id: id
      },function(data){
        var ob_n = "#das-group";
        das._updateOvSum(ob_n,data.ds.summary);
        das._drawCallByHr(ob_n,data.chart.call_by_hrs);
        das._drawCallDurByHr(ob_n,data.chart.call_by_hrs);
        das._drawCallByDRange(ob_n,data.chart.call_by_rngs);
        das._updateTblUsrsSummary({ds_users: data.table.user_summary});
        das._drawAnaInfo(ob_n,data.table.ana_demo);
        //das._updateTblTopKeyword(ob_n,data.table.top_keyword);
        das._drawTimeLine(id);
        das._updateGroupInfo(data.ds.group);
        appl.dialog.hideWaiting();
      });
    }
    $("#das-group").css("display","initial");
    updateView();
  },
  displayDasUsr: function(nd){
    function updateView(){
      var id = nd.id.replace("user-","");
      jQuery.get(Routes.das_data_dashboard_index_path(),{
        q: 'user', d: das.dasDateDb, id: id
      },function(data){
        var ob_n = "#das-usr";
        das._updateOvSum(ob_n,data.ds.summary);
        das._drawCallByHr(ob_n,data.chart.call_by_hrs);
        das._drawCallDurByHr(ob_n,data.chart.call_by_hrs);
        das._drawCallByDRange(ob_n,data.chart.call_by_rngs);
        das._drawAnaInfo(ob_n,data.table.ana_demo);
        //das._updateTblTopKeyword(ob_n,data.table.top_keyword);
        das._updateUserInfo(data.ds.user);
        das._drawUserTimeLine(id);
        appl.dialog.hideWaiting();
      });
    }
    $("#das-usr").css("display","initial");
    updateView();
  },
  hideDas: function(){
    $("#das-all, #das-groups, #das-group, #das-usr").css("display","none");
  },
  displayDas: function(node){
    var t = "root-all";
    if(isNotNull(node)){ t = node.id; }
    
    function isDasRoot(){
      return t.startsWith('root-all');
    }
    
    function isDasGroups(){
      return t.startsWith('group-all');
    }
    
    function isDasGroup(){
      return t.startsWith('group-');
    }
    
    function isDasUser(){
      return t.startsWith('user-');
    }
    
    function selectDasToShow(){
      if (isDasRoot()) {
        das.displayDasAll(node);
      } else if (isDasGroups()) {
        das.displayDasGrps(node);
      } else if (isDasGroup()) {
        das.displayDasGrp(node);
      } else if (isDasUser()) {
        das.displayDasUsr(node);
      }
    }
    appl.dialog.showWaiting();
    das.hideDas();
    selectDasToShow();
    das.currentNode = node;
  },
  refreshDas: function(){
    function canRefresh(){
      return (isPresent(das.currentNode) && das.autoRefreshDas);
    }
    if (canRefresh()) {
      das.displayDas(das.currentNode);
      setTimeout("das.refreshDas()",appl.sToms(das.intervalUpdateSec));
    }
  },
  drawTreeView: function(){
    var js_opt = {
      'core': {
        'animation': 0,
        'data': {
          'url': function (node) {
            return Routes.tv_data_dashboard_index_path();
          },
          'data': function (node) {
            return { 'id': node.id };
          }
        }
      },
      'plugins': ["wholerow"]
    }
    $('#das-treeview').jstree(js_opt).on('changed.jstree',function(e,data){
      if (data.selected.length > 0) {
        das.displayDas(data.instance.get_node(data.selected[0]));
      }
    }).on('loaded.jstree',function(e,data){
      try {
        var node = data.instance.get_node(data.instance.get_node("#").children[0]);
        das.displayDas(node);        
      } catch(e){
        das.displayDas();
      }
    });
  },
  resize: function(){
    var wi_h = $("#das-left-panel").height();
    $("#das-right-panel").height(wi_h);
  },
  calendarBtn: function(){
    function updateField(){
      das.dasDateDb = das.dasDate.format("YYYY-MM-DD");
      $("#btn-cur-date #cur-date-val").html(das.dasDate.format("D MMM YYYY"));
      if(isPresent(das.currentNode)){
        das.displayDas(das.currentNode);
      }
    }
    $("#btn-prev-day").on('click',function(){
      das.dasDate.subtract(1,'days');
      if (das.dasDate.isBefore(moment().subtract(1,'months'))){
        das.dasDate = moment().subtract(1,'months');
        appl.noty.error("Not allowed to see data that older that 1 month.");
      }
      updateField();
    });
    $("#btn-next-day").on('click',function(){
      das.dasDate.add(1,'days');
      if (das.dasDate.isAfter(moment())){
        das.dasDate = moment();
      }
      updateField();
    });
    $("#btn-today").on('click',function(){
      das.dasDate = moment();
      updateField();
    });
    var picker = new Pikaday({
      field: $('#cur-date-input')[0],
      trigger: $("#btn-cur-date")[0],
      maxDate: moment().toDate()
    });
    $('#cur-date-input').on('change',function(){
      das.dasDate = moment($(this).val());
      updateField();
    });
    updateField();
  },
  begUpdateDas: function(){
    setTimeout("das.refreshDas()",appl.sToms(das.intervalUpdateSec));
  },
  initResize: function(){
    das.resize();
    $(window).on('resize', function(){ das.resize(); });
  },
  initBtn: function(){
    $(".btn-select-dt").on('click',function(){
      $("button[name=ds-current-dt]").text($(this).text());
    });
  },
  init: function(){
    das.intervalUpdateSec = gon.settings.update_sec;
    das.autoRefreshDas = gon.settings.auto_update;
    das.initBtn();
    das.calendarBtn();
    das.drawTreeView();
    das.begUpdateDas();
    das.initResize();
    
    //make pie
    /*
    var chart2 = c3.generate({
      bindto: "#das-all #gp-call_type",
      size: { height: 250 },
      data: {
          columns: [
              ['Billing Inquiry', 40],
              ['Payment Inquiry', 60],
              ['Product Inquiry', 15],
              ['Complain', 10],
              ['Other',5]
          ],
          type : 'pie'
      }
    });
    */
  }
}

jQuery(document).on('ready page:load',function(){das.init();});