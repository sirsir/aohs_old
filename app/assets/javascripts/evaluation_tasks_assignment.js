var fnAssignment = {
  
  _findAssignedData: function(){
    var ds = {};
    function getCase(){
      var o = $("input[name=case_name]:checked");
      ds.assigned_case = o.val();
      return true;
    }
    
    function getAssignedDate(){
      var ad = $("input[name=data_assigned_datetime]");
      ds.assigned_daterange = ad.val();
      var ac = $("input[name=data_content_datetime]");
      ds.content_daterange = ac.val();
      return true;
    }
    
    function updateView(data){
      var htm = appl.hbsTemplate('template-tbl-assigned-list');
      $('#tbl-assigned-list').html(htm(data.assigned_summary.by_qa));
      $('input[name=unassign_user_id]').off('click').on('click',function(){
        var o = $(this);
        if(o.prop('checked')){
          o.closest('tr').addClass('checked');
        } else {
          o.closest('tr').removeClass('checked');
        }
      });
      $('input[name=n_of_unassign]').off('blur').on('blur',function(){
        var o = $(this);
        if(parseInt(o.val()) < 0 || parseInt(o.val()) > parseInt(o.attr("max"))){
          o.val(o.attr("max"));
        }
      });
    }
    
    function findData(){
      appl.dialog.showWaiting();
      var url = Routes.query_assigned_evaluation_tasks_path();
      jQuery.post(url,jQuery.extend({
        step: 'checkassigned',
        task: ds
      },appl.defaultPostParams()),function(data){
        updateView(data);
        appl.dialog.hideWaiting();
      });
    }
    
    if(getCase() && getAssignedDate()){
      findData();
    }
  },
  
  _unassignTask: function(){
    var ds = [];
    function getData(){
      $('#tbl-assigned-list table tbody tr').each(function(){
        var or = $(this);
        var oc = $('input[name=unassign_user_id]',or);
        if(oc.prop('checked')){
          ds.push({
            assignee_id: oc.val(),
            nofunassign: $("input[name=\"n_of_unassign\"]",or).val()
          });
        }
      });
      return true;
    }
    
    if(getData()){
      bootbox.confirm("Are you soure to unassign?",function(result){
        if(result){
          appl.dialog.showWaiting();
          var url = Routes.query_assigned_evaluation_tasks_path();
          jQuery.post(url,jQuery.extend({
            step: 'dounassign',
            task: { unassign: ds }
          },appl.defaultPostParams()),function(data){
            appl.noty.info("Unassign has been successfully");
            appl.reloadPage();
          });
        }
      });
    } else {
      appl.noty.error("No selected to unassign.");
    }
  },
  
  init: function(){
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
    
    function bindButton(){
      $("button#btn-search-assigned").on('click',function(){
        fnAssignment._findAssignedData();
      });
      $("button#btn-unassign").on('click',function(){
        fnAssignment._unassignTask();
      });
    }
    
    setButtonStyle();
    bindButton();
  }
};

jQuery(document).on('ready page:load',function(){ fnAssignment.init(); });