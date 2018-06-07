var fnEdit = {

  validateForm: function()
  {
    function validGrade() {
      var err3 = false;
      var preScore = null;
      
      $("#tbl-form-grade tbody tr").each(function(){
        var err2 = false;
        var o = $(this);
        /* title */
        var ti = $("input.form-grade-title",o).val();
        if (ti.length <= 0) {
          err2 = true;
        }
        /* range */
        var up = parseInt($("input.form-grade-upper",o).val());
        if (up.length <= 0) {
          err2 = true;
        } else {
          up = parseInt(up);
          if(preScore === null){
            preScore = 100;
            if(up !== 100){
              err2 = true;
            }
          } else {
            if((preScore - up) <= 1){
              err2 = true;
            }
            preScore = up;
          }
        }
        if (err2) {
          o.addClass('has-error');
          err3 = true;
        } else {
          o.removeClass('has-error');
        }
      });
      if (preScore <= 0) {
        $("#tbl-form-grade tbody tr:last").addClass('has-error');
        err3 = true;
      }
      if ($("#tbl-form-grade tbody tr").length < 2){
        $("#tbl-form-grade tbody tr:last").addClass('has-error');
        err3 = true;
      }
      return err3;
    }
    
    if(validGrade()){
      // true if error
      appl.noty.error("Some field are invalid.");
      return false;
    } else {
      appl.dialog.showWaiting();
      return true;
    }
  },
  
  init: function(){
    
    function addRowGrade() {
      var t = $("#row_grade").html();
      if ($("#tbl-form-grade tbody tr").length < 10) {
        $("#tbl-form-grade tbody").append(t);
      } else {
        appl.noty.info("Not allowed to add score range more than 10."); 
      }
      $("button.btn-remove-grade").off('click').on('click',function(){
        $(this).closest('tr').remove();  
      });
    }

    function initButton() {
      $("#btn-add-grade").off('click').on('click',function(){
        addRowGrade();
      });
      $("button.btn-remove-grade").off('click').on('click',function(){
        $(this).closest('tr').remove();  
      });
    }
    
    function initForm() {
      $("form#edit_evaluation_grade_setting_" + gon.params.id).off('submit').on('submit',function(){
        return fnEdit.validateForm();  
      });
      $("form#new_evaluation_grade_setting").off('submit').on('submit',function(){
        return fnEdit.validateForm();  
      });
    }
    
    initButton();
    initForm();
  }
};

jQuery(document).on('ready page:load',function(){ fnEdit.init(); });
