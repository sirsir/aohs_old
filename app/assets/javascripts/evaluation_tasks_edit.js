var fnTaskEdit = {
  ds: {},
  dsSettings: {},
  dsUsers: [],
  dsAssignedUsers: [],
  
  isScheduleMode: function(){
    return (gon.params.mode == "schedule");  
  },
  
  _setStep: function(i){
    i = i || 1;
    $("div.item-step").removeClass('selected');
    $("#box-step-" + i).addClass('selected');
  },
  
  _processURL: function(){
    return Routes.query_evaluation_tasks_path({ task_id: gon.params.id });  
  },
  
  _queryCheck: function(){
    var ds = {};
    function getCase(){
      var o = $("input[name=case_name]:checked");
      if(o.length > 0){
        ds.case_name = o.val();
      }
      return true;
    }
    
    function getDataFilter(){
      var od = $("input[name=data_datetimerange]");
      if(od.length > 0){
        ds.filter_daterange = od.val();
      }
      var ox = $("input[name=data_extension]");
      ds.filter_extension = ox.val();
      var oa = $("input[name=data_ani]");
      ds.filter_ani = oa.val();
      var on = $("input[name=data_dnis]");
      ds.filter_dnis = on.val();
      var odf = $("input[name=data_duration_from");
      ds.filter_duration_from = odf.val();
      var odt = $("input[name=data_duration_to");
      ds.filter_duration_to = odt.val();
      var oag = $("select[name=data_agent_id] option:selected");
      if(oag.length > 0){
        ds.filter_agent_id = oag.val();
      }
      var ogr = $("select[name=data_group_id] option:selected");
      if(ogr.length > 0){
        ds.filter_group_id = ogr.val();
      }
      return true;
    }
    
    function valid(){
      jQuery.extend(fnTaskEdit.dsSettings,ds);
      return true;
    }
    
    return getCase() && getDataFilter() && valid();
  },
  
  _renderNewAssignmentSummary: function(data){
    if(data !== undefined){
      var htm = appl.getHtmlTemplate("#template_data_summary_by_date");
      $("input[name=select_data_limit_count]").val(data.record_count);
      $("input[name=select_data_limit_count]").attr("data-max-records",data.record_count);
      $("#help-select_data_limit").html("Unit: record, value between 1 - " + data.record_count);
      $("input[name=select_data_limit_duration]").val((data.total_duration/3600).toFixed(2));
      $("input[name=select_data_limit_duration]").attr("data-max-duration",(data.total_duration/3600).toFixed(2));
      $("#help-select_duration_limit").html("Unit: hour, value between 0.1 - " + (data.total_duration/3600).toFixed(2));
      if(data.record_count > 0){
        $("div#block-tbl-data-bydate").html(htm(data.by_date));
        $("#block-no-result-select").addClass('hide-block');
      } else {
        $("div#block-tbl-data-bydate").html("");
        $("#block-no-result-select").removeClass('hide-block');
      }      
    }
  },
  
  _doCheckData: function(goNext){
    goNext = goNext || false;
    
    function getData(){
      jQuery.post(fnTaskEdit._processURL(),jQuery.extend({
        step: 'checkdata',
        task: fnTaskEdit.dsSettings
      },appl.defaultPostParams()),function(data){
        fnTaskEdit._renderNewAssignmentSummary(data.new_assignment_summary);
        if(goNext){
          if(fnTaskEdit.isScheduleMode() || data.new_assignment_summary.record_count > 0){
            fnTaskEdit._initStepAssign();
          } else {
            appl.noty.error("No selected data. please change your conditions.");
          }
        }
        appl.dialog.hideWaiting();
      });
    }
    
    if(fnTaskEdit._queryCheck()){
      appl.dialog.showWaiting();
      getData();        
    }
  },
  
  _initStepAssign: function(){
    function renderTableUser(){
      var tblOpts = {
        "scrollX": true,
        "paging": true,
        "searching": true,
        "info": false,
        "dom": 'ftp'
      };
      
      var htm_a = appl.getHtmlTemplate("#template_table_avail_users");
      
      var oa = $("#block-available-users");
      oa.html(htm_a(fnTaskEdit.dsUsers));
      fnTaskEdit._oTblAvailUser = $("table", oa).DataTable(jQuery.extend({ "columnDefs": [{"targets": [3,4,5,6], "visible": false }, { className: "td-move-btn", "targets": [2,5] }] }, tblOpts));
      fnTaskEdit._oTblAvailUser.on('draw',function(){
        $("button.btn-select", this).off('click').on('click',function(){
          var row = $(this).parent('td').parent('tr');
          var r = fnTaskEdit._oTblAvailUser.row(row);
          fnTaskEdit._oTblAssignUser.row.add(r.data()).draw();
          fnTaskEdit._oTblAvailUser.rows(row).remove();
          fnTaskEdit._oTblAvailUser.draw();
        });
      }).draw();
      
      var ob = $("#block-assigned-users");
      ob.html(htm_a(fnTaskEdit.dsAssignedUsers));
      var bCols = [2,6];
      if(fnTaskEdit.isScheduleMode()){
        bCols = [2,3,4,6];
      }
      fnTaskEdit._oTblAssignUser = $("table", ob).DataTable(jQuery.extend({ "columnDefs": [{"targets": bCols, "visible": false },{ className: "td-move-btn", "targets": [2,5] }] }, tblOpts));
      fnTaskEdit._oTblAssignUser.on('draw',function(){
        $("button.btn-unselect", this).off('click').on('click',function(){
          var row = $(this).parent('td').parent('tr');
          var r = fnTaskEdit._oTblAssignUser.row(row);
          fnTaskEdit._oTblAvailUser.row.add(r.data()).draw();
          fnTaskEdit._oTblAssignUser.rows(row).remove();
          fnTaskEdit._oTblAssignUser.draw();
        });
      }).draw();
    }
    
    $("#block-page-1").addClass('hide-block');
    $("#block-page-2").removeClass('hide-block');
    renderTableUser();
    fnTaskEdit._setStep(2);
  },

  _checkAssign: function(doCheck){
    var ds = {};
    doCheck = doCheck || false;
    
    function getScheduleType(){
      return true;  
    }
    
    function getSelection(){
      $("#form-group-data-select").removeClass('has-error');
      var o = $("input[name=select_data_limit]:checked");
      ds.assign_select = o.val();
      if(o.val() == "all" || o.val() == "agent_available"){
        return true;
      } else if(o.val() == "limit_record"){
        var n = parseInt($("input[name=select_data_limit_count]").val()) || -1;
        var m = parseInt($("input[name=select_data_limit_count]").attr("data-max-records"));
        if(n > 0 && (n <= m || fnTaskEdit.isScheduleMode())){
          ds.assign_limit_records = n;
          return true;
        }
      } else if(o.val() == "limit_duration"){
        var n2 = parseFloat($("input[name=select_data_limit_duration]").val()) || -1;
        var m2 = parseFloat($("input[name=select_data_limit_duration]").attr("data-max-duration"));
        if(n2 > 0 && (n2 <= m2 || fnTaskEdit.isScheduleMode())){
          ds.assign_limit_duration = n2;
          return true;
        }
      }
      $("#form-group-data-select").addClass('has-error');
      return false;
    }
    
    function getMethod(){
      var o = $("input[name=limit_select_type]:checked");
      ds.assign_method = o.val();
      return true;
    }
    
    function getPerPerson(){
      $("#form-group-perperson").removeClass('has-error');
      var o = $("input[name=per_person_by]:checked");
      ds.assign_perperson = o.val();
      if(o.val() == "custom_record"){
        var n = parseInt($("input[name=assign_custom_record]").val());
        if(n > 0){
          ds.assign_custom_records = n;
          return true;
        }
      } else if(o.val() == "custom_duration"){
        var n2 = parseFloat($("input[name=assign_custom_duration]").val());
        if(n2 > 0){
          ds.assign_custom_duration = n2;
          return true;
        }
      } else if(o.val() == "avg_record" || o.val() == "avg_duration"){
        return true;
      }
      $("#form-group-perperson").addClass('has-error');
      return false;
    }
    
    function getUsers(){
      $("#form-group-select-users").removeClass('has-error');
      ds.assign_users = [];
      fnTaskEdit._oTblAssignUser.rows().eq(0).each(function(index){
        var d = fnTaskEdit._oTblAssignUser.row(index).data();
        ds.assign_users.push(parseInt(d[6]));
      });
      if(ds.assign_users.length > 0){
        return true;
      }
      $("#form-group-select-users").addClass('has-error');
      return false;
    }
    
    function updateResult(data){
      if(isDefined(data)){
        data.assigned_users.forEach(function(u){
          var index = fnTaskEdit.dsSettings.assign_users.findIndex(parseInt(u.user_id));
          var r = fnTaskEdit._oTblAssignUser.row(index);
          var d = r.data();
          d[3] = u.record_count;
          d[4] = u.record_count + parseInt(d[1]);
          r.data(d);
        });
        fnTaskEdit._oTblAssignUser.draw();
      }
    }
    
    function queryCheck(){
      jQuery.post(fnTaskEdit._processURL(),jQuery.extend({
        step: 'checkassign',
        task: fnTaskEdit.dsSettings
      },appl.defaultPostParams()),function(data){
        updateResult(data.assign_user_summary);
        if(!doCheck){
          $("#block-page-2").addClass('hide-block');
          $("#block-page-3").removeClass('hide-block');
          fnTaskEdit._setStep(3);
        }
        appl.dialog.hideWaiting();
      });
    }
    
    if(getScheduleType() && getSelection() && getMethod() && getPerPerson() && getUsers()){
      jQuery.extend(fnTaskEdit.dsSettings,ds);
      appl.dialog.showWaiting();
      queryCheck();
    } else {
      appl.noty.error("Invalid settings, please check your settings.");
    }
  },
  
  _doSubmit: function(){
    var ds = {};
    
    function getTaskProp(){
      $("#field-group-startdate").removeClass('has-error');
      $("#field-group-enddate").removeClass('has-error');
      $("#field-group-title").removeClass('has-error');
      var ot = $("input[name=task_title]");
      if(ot.val().length > 0){
        ds.task_title = ot.val();
      } else {
        if(fnTaskEdit.isScheduleMode()){
          $("#field-group-title").addClass('has-error');
          return false;
        }
      }
      var od = $("textarea[name=task_description]");
      if(ot.val().length > 0){
        ds.task_description = od.val();
      }
      var os = $("input[name=task_start_date]");
      if(os.val().length > 0){
        ds.task_start_date = os.val();
      }
      var oa = $("select#duedate_type option:selected");
      if(oa.length > 0){
        if(oa.val() === "within"){
          var oy = $("input[name=task_within_days]");
          if(oy.length > 0){
            ds.task_expiry_in = oy.val();
          }
        } else if(oa.val() == "custom"){
          var oe = $("input[name=task_end_date]");
          if(oe.val().length > 0){
            ds.task_end_date = oe.val();
          }
        }
      }
      if(isDefined(ds.task_start_date) && isDefined(ds.task_end_date)){
        if(moment(ds.task_end_date).isBefore(ds.task_start_date)){
          $("#field-group-startdate").addClass('has-error');
          $("#field-group-enddate").addClass('has-error');
          return false;
        }
      }
      return true;
    }
    
    function submitTask(){
      appl.dialog.showWaiting();
      jQuery.post(fnTaskEdit._processURL(),jQuery.extend({
        step: 'submittask',
        task: fnTaskEdit.dsSettings
      },appl.defaultPostParams()),function(data){
        if(fnTaskEdit.isScheduleMode()){
          appl.redirectTo(Routes.evaluation_tasks_path());
        } else {
          $("#block-page-3").addClass('hide-block');
          $("#block-page-4").removeClass('hide-block');
          fnTaskEdit._setStep(4);
          appl.dialog.hideWaiting();
        }
      });
    }
    
    if(getTaskProp()){
      jQuery.extend(fnTaskEdit.dsSettings,ds);
      bootbox.confirm("Are you sure to save assignment?",function(result){
        if(result){
          submitTask();
        }
      });
    }
  },
  
  init: function()
  {
    function loadSrc(){
      var oe = $("#src-evaluators");
      fnTaskEdit.dsUsers = jQuery.parseJSON(oe.html());
      fnTaskEdit.dsAssignedUsers = fnTaskEdit.dsUsers.exclude(function(u){
        return !u.selected;
      });
      fnTaskEdit.dsUsers = fnTaskEdit.dsUsers.remove(function(u){
        return u.selected;  
      });
      fnTaskEdit.dsSettings.task_type = $("input[name=task_type]").val();
    }
    
    function setFormEvent(){
      $("form#new_evaluation_task").on('submit',function(){
        fnTaskEdit._doBeforeSubmit();
        return false;  
      });
      $("button#btn-assign-check-data").on('click',function(){
        fnTaskEdit._doCheckData();
      });
      $("button#btn-assign-next-assign").on('click',function(){
        fnTaskEdit._doCheckData(true);
      });
      $("button#btn-assign-prev-data").on('click',function(){
        $("#block-page-1").removeClass('hide-block');
        $("#block-page-2").addClass('hide-block');
        fnTaskEdit._setStep(1);
      });
      $("button#btn-assign-next-options").on('click',function(){
        fnTaskEdit._checkAssign();
      });
      $("button#btn-assign-check").on('click',function(){
        fnTaskEdit._checkAssign(true);
      });
      $("button#btn-assign-prev-assign").on('click',function(){
        $("#block-page-2").removeClass('hide-block');
        $("#block-page-3").addClass('hide-block');
        fnTaskEdit._setStep(2);
      });
      $("button#btn-assign-next-submit").on('click',function(){
        fnTaskEdit._doSubmit(); 
      });
      $("input.task-date-picker").datetimepicker({
        format: 'YYYY-MM-DD'
      });
      $("select#duedate_type").on('change',function(){
        var ov = $("option:selected", this).val();
        $("input#task_end_date").addClass('hidden');
        $("input#task_within_days").addClass('hidden');
        if(ov === "within"){
          $("input#task_within_days").removeClass('hidden');
        } else if(ov == "custom"){
          $("input#task_end_date").removeClass('hidden');  
        }
      });
    }
    
    function setButtonStyle(){
      $('form input:radio').iCheck({
        labelHover: false,
        cursor: true,
        handle: 'radio',
        radioClass: 'iradio_square-blue'
      });
      $('form input:checkbox').iCheck({
        labelHover: false,
        cursor: true,
        handle: 'checkbox',
        checkboxClass: 'icheckbox_square-blue'
      });
    }
    
    loadSrc();
    setFormEvent();
    setButtonStyle();
  }
};

jQuery(document).on('ready page:load',function(){ fnTaskEdit.init(); });