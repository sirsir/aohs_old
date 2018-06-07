var fnIndex = {
  loadGroupInfo: function(){
    fnIndex.dsQuestionGroup = jQuery.parseJSON($("#data-question-groups").html());  
  },
  
  deleteGroupQuestion: function(){
    bootbox.confirm({
    message: "Are you sure to delete?",
    callback: function(result){
      if(result){
        jQuery.getJSON(Routes.delete_group_evaluation_questions_path(),{
          id: gon.params.question_group_id,  
        },function(){
          
        });
      }
    }
    });
  },
  
  groupTitleDialog: function(){
    function changeGroupTitle(newTitle){
      jQuery.getJSON(Routes.update_group_evaluation_questions_path(),{
        id: gon.params.question_group_id,
        title: newTitle },
      function(data){
        if(data.errors.length > 0){
          fnIndex.groupTitleDialog();
          $("form.bootbox-form").append($('<div/>',{ class: 'help-block', text: data.errors.join(",") }));
        } else {
          window.location.reload(); 
        }
      });
    }
    function getGroup(){
      return fnIndex.dsQuestionGroup.find(function(x){
        return x.id == parseInt(gon.params.question_group_id);  
      });
    }
    bootbox.prompt({
      title: "Group Question",
      inputType: 'text',
      animate: false,
      value: getGroup().title,
      callback: function (result) {
        if(result !== null){
          changeGroupTitle(result);
        }
      }
    });
  },
  
  init: function(){
    fnIndex.loadGroupInfo();
    $("button#btn-change-group-title").on('click',function(){
      fnIndex.groupTitleDialog();
    });
    $("button#btn-delete-group").on('click',function(){
      fnIndex.deleteGroupQuestion();
    });
  }
};
jQuery(document).on('ready page:load',function(){ fnIndex.init(); });