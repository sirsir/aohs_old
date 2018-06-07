var fnAsm = {

  checkData: function(){
    function getDataFilter(){
      var f = {};
      f.call_date_range = $("input#fd_call_date").val();
      f.ext = $("#fd_extension").val();
      f.ani = $("#fd_ani").val();
      f.dnis = $("#fd_dnis").val();
      return f;
    }
    function renderResult(){
      var htm = appl.getHtmlTemplate("#template-unassigned-table");
      $("#tbl-unassign-list").html(htm(fnAsm.ds.assignees));
    }
    fnAsm.dsFilter = getDataFilter();
    jQuery.getJSON(Routes.unassignment_evaluation_tasks_path(),{
      doact: 'check',
      data_filter: fnAsm.dsFilter
    },function(data){
      fnAsm.ds = data;
      if(fnAsm.ds.assignees.length > 0){
        renderResult();
        $("#block-select-data").addClass('hide-block');
        $("#block-unassign-list").removeClass('hide-block');
      } else {
        appl.noty.error("No data to unassign.");
      }
    });
  },
  
  submitAssign: function(){
    function getUnAssign(){
      var usrs = [];
      $("#tbl-unassign-list input.fd_unassign_count").each(function(){
        var o = $(this);
        usrs.push({ assignee_id: parseInt(o.attr("data-assignee-id")), unassign_count: parseInt(o.val()) });
      });
      return {
        assignees: usrs
      };
    }
    function renderResult(){
      var htm = appl.getHtmlTemplate("#template-assigned-table");
      $("#tbl-unassign-summary").html(htm(fnAsm.ds.assignees));
    }
    bootbox.confirm("Are you sure to unassignment?",
    function(result){
      if(result){
        fnAsm.unassign_data = getUnAssign();
        jQuery.getJSON(Routes.unassignment_evaluation_tasks_path(),{
          doact: 'submit',
          data_filter: fnAsm.dsFilter,
          data_unassign: fnAsm.unassign_data
        },function(data){
          fnAsm.ds = data;
          renderResult();
          $("#block-unassign-list").addClass('hide-block');
          $("#block-unassign-result").removeClass('hide-block');
        });
      }
    });
  },
  
  init: function(){
    $("#btn-next-unassign").on('click',function(){
      fnAsm.checkData();
    });
    $("#btn-next-summary").on('click',function(){
      fnAsm.submitAssign(); 
    });
    $("#btn-prev-select").on('click',function(){
      $("#block-select-data").removeClass('hide-block');
      $("#block-unassign-list").addClass('hide-block');
    });
  }
};

jQuery(document).on('ready page:load',function(){ fnAsm.init(); });