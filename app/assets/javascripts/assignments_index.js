//= require 'base_form'
//= require 'charts'

var fnIndex = {
  _intervalTimeTaskQuerySec: 1,
  _autoupdateEnable: true,
  _loadingA: false,
  _loadingB: false,
  
  _getTeamSummary: function(){
      
  },
  
  _getAssignmentData: function(){
    
    function destroyView(){
      try {
        fnIndex._oTblAssignedTask.destroy();  
      } catch(e){}
      try {
        fnIndex._oTblClosedTask.destroy();
      } catch(e){}
    }
    
    function applyResult(data){
      var htm = appl.hbsTemplate('template-assigned-list');
      $("#tbl-task-assigned").html(htm(data.list));
      var tblOpts = {
        "scrollX": true,
        "paging": true,
        "searching": false,
        "info": false,
        "dom": 'ftp'
      };
      fnIndex._oTblAssignedTask = $("#tbl-task-assigned").DataTable(jQuery.extend({}, tblOpts));
      fnIndex._oTblAssignedTask.on('draw',function(){
        $("button.btn-do-evaluate", this).off('click').on('click',function(){
          var bo = $(this);
          appl.openUrl(Routes.call_history_path(parseInt(bo.attr("data-voice-log-id"))));
        });
      }).draw();
      $("#lb-assigned-task-count").html(data.list.length);
    }
    
    function applyCloseList(data){
      var htm = appl.hbsTemplate('template-closed-list');
      $("#tbl-task-closed").html(htm(data.list));
      var tblOpts = {
        "scrollX": true,
        "paging": true,
        "searching": false,
        "info": false,
        "dom": 'ftp'
      };
      fnIndex._oTblClosedTask = $("#tbl-task-closed").DataTable(jQuery.extend({}, tblOpts));
      fnIndex._oTblClosedTask.on('draw',function(){
        $("button.btn-do-evaluate", this).off('click').on('click',function(){
          var bo = $(this);
          appl.openUrl(Routes.call_history_path(parseInt(bo.attr("data-voice-log-id"))));
        });
      }).draw();
    }
    
    function renderMyChart(data){
      var oc = $("#chart-my-task-summary canvas");
      var cOpts = {
        type: 'doughnut',
        data: {
        datasets: [{
          data: data.data,
          backgroundColor: data.colors,
          borderColor: data.colors_bd,
          borderWidth: 1
        }],
        labels: data.labels
      }};
      var occ = new Chart(oc, cOpts);
    }
    
    appl.dialog.showWaiting();
    fnIndex._loadingA = true;
    var url = Routes.query_assignments_path();
    jQuery.getJSON(url,function(data){
      destroyView();
      applyResult(data.assigned);
      applyCloseList(data.closed);
      renderMyChart(data.chart_mytask_summary);
      fnIndex._loadingA = false;
      appl.dialog.hideWaiting();
    });
  },
  
  _getSelectedAssignedRow: function(){
    var ids = [];
    $("input[name=row_select]:checked").each(function(){
      ids.push($(this).val());  
    });
    return ids;
  },
  
  assignToDialog: function(){
    function assignTo(uid){
      jQuery.post(Routes.change_assignee_evaluation_tasks_path(),jQuery.extend({
        doact: 'assignto',
        assignee: uid,
        voice_logs_id: fnIndex._getSelectedAssignedRow()
      },appl.defaultPostParams()),function(data){
        fnIndex._getAssignmentData();
      });
    }
    
    var opts = {
      title: 'Assign',
      message: appl.hbsTemplate('template-assigned-dialog')(),
      buttons: {
        cancel: {
          label: "Cancel",
          className: 'btn-default',
          callback: function(){ }
        },
        assign: {
          label: "Assign",
          className: 'btn-primary',
          callback: function(){
            var uid = $("select[name=fd-assignee] option:selected",this).val();
            assignTo(uid);
          }
        }
      }
    };
    bootbox.dialog(opts);
  },
  
  resizeTbls: function(){
    try {
      fnIndex._oTblAssignedTask.columns.adjust();
      fnIndex._oTblClosedTask.columns.adjust();          
    } catch(e){}
  },
  
  onResize: function(){
    function doResize(){
      fnIndex.resizeTbls();
    }
    $(window).off('resize').on('resize',function(){
      doResize();
    });
  },
  
  init: function(){
    function checkPageActive(){
      $(window).on('focus',function(){
        fnIndex._autoupdateEnable = true;
      }).on('blur',function(){
        fnIndex._autoupdateEnable = false;
      });
    }
    
    function setButtons(){
      $("a.tab-data-view").on('click',function(){
        var ot = $(this);
        $("a.tab-data-view",ot.parent().parent()).removeClass('active');
        ot.addClass('active');
        $("div.block-task-list").addClass('hide-block');
        $("div" + ot.attr('href')).removeClass('hide-block');
        fnIndex.resizeTbls();
      });
      $("button#btn-bulk-reassign").on('click',function(){
        if(fnIndex._getSelectedAssignedRow().length > 0){
          fnIndex.assignToDialog();
        } else {
          appl.noty.error("No selected task.");
        }
      });
    }
    
    function intervalUpdate(){
      setInterval(function(){
        if(fnIndex._autoupdateEnable){
          if(!fnIndex._loadingA){
            fnIndex._getAssignmentData();
          }
        }
      },1000*30);
    }
    
    setButtons();
    fnIndex._getAssignmentData();
    fnIndex._getTeamSummary();
    checkPageActive();
    intervalUpdate();
  }
};

jQuery(document).on('ready page:load',function(){ fnIndex.init(); });