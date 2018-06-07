//var callEvaluate = {
//  formId: null,
//  voiceId: null,
//  showEvaluatedScore: function()
//  {
//    // show evaluated score in left panel
//    function showScore()
//    {
//      var url = Routes.evaluated_score_voice_log_path(callEvaluate.voiceId);
//      jQuery.get(url,function(data){
//        var t = appl.getHtmlTemplate("#item-evaluated-template");
//        $("#box-evaluation-score table").html(t({list: data}));
//      });
//    }
//    setTimeout(showScore, 1500);
//  },
//  loadForm: function()
//  {
//    var url, dsForm;
//    var htmCate = appl.getHtmlTemplate("#item-category-template");
//    var htmCrit = appl.getHtmlTemplate("#item-crit-template");
//    
//    function renderCritHtml(node)
//    {
//      var htm = "";
//      node.items.forEach(function(item){
//        htm = htm + htmCrit(item);
//      });
//      return htm;
//    }
//    
//    function renderHtml(node)
//    {
//      var nodes = ((node && node.childs) ? node.childs : dsForm.data);
//      var htm = "";
//      
//      nodes.forEach(function(node){
//        if (isPresent(node.items)) {
//          node.item_html = renderCritHtml(node);
//        }
//        if (isPresent(node.childs)){
//          node.child_html = renderHtml(node);
//        }
//        htm = htm + htmCate(node);
//      });
//      
//      return htm;
//    }
//    
//    function renderForm(d)
//    {
//      dsForm = d;
//      $("#box-evaluation-form").html(renderHtml());
//    }
//    
//    if (callEvaluate.formId != 0) {
//      var url = Routes.list_evaluation_plan_evaluation_criteria_path({ evaluation_plan_id: callEvaluate.formId });
//      jQuery.get(url,function(d){
//        renderForm(d);
//        callEvaluate.setFormData();
//        callEvaluate.showHideScoreDescription();
//      });
//    }
//  },
//  update: function()
//  {
//    var err = false;
//    
//    function getFormData()
//    {
//      var a=[], k='.panel-evaluation';
//      
//      function getScore(type, o)
//      {
//        var a = [], isRequired = true;
//        
//        if (type == 'radio') {
//          //radio
//          var b = o.find('input:checked');
//          if (b.length) {
//            a.push({id: b.attr('data-id'), score: b.val()});
//          }
//        } else {
//          //checkbox
//          o.find('input:checked').each(function(){
//            a.push({id: $(this).attr('data-id'), score: $(this).val()});
//          });
//          isRequired = false;
//        }
//        
//        o.removeClass('has-error');
//        if (isRequired && (a.length <= 0)) {
//          o.addClass('has-error');
//          err = true;
//        }
//        
//        return a;
//      }
//      
//      function getItem()
//      {
//        var o = $(this);
//        a.push({
//          id: o.attr('data-id'),
//          items: getScore(o.attr('data-score-type'),o)
//        });      
//      }
//      
//      $(k + ' .evl-item').each(getItem);
//      return {
//        criteria: a
//      };
//    }
//    
//    function getAgentInfo()
//    {
//      var o = $("#evl_usr_id option:selected");
//      if (isPresent(o)) {
//        return {
//          agent_id: o.val(),
//          agent_name: o.text() 
//        }
//      }
//      err = true;
//      return null;
//    }
//    
//    function getGroupInfo()
//    {
//      var o = $("#evl_group_id option:selected");
//      if (isPresent(o)) {
//        return {
//          group_id: o.val(),
//          group_name: o.text() 
//        }
//      }
//      err = true;
//      return null;
//    }
//    
//    function getComment()
//    {
//      return {
//        comment: $("textarea[name=evl_comment]").val() || ""
//      }
//    }
//    
//    function getCheckResult()
//    {
//      var a = $("#evl_check_result").val();
//      var b = $("#evl_check_comment").val();
//      if (a == 'W') {
//        return { check_result: { check_result: 'wrong', comment: b } }
//      }
//      return null;
//    }
//    
//    function updateData(d)
//    {
//      appl.dialog.showWaiting();
//      jQuery.post(Routes.evaluate_voice_log_path(callEvaluate.voiceId),{
//        authenticity_token: window._frmTk,
//        form_id: callEvaluate.formId,
//        data: JSON.stringify(d),
//        mode: 'evaluate'
//      },function(data){
//        callEvaluate.showEvaluatedScore();
//        callEvaluate.setFormData();
//        callEvaluate.hideMoreInfo();
//        appl.dialog.hideWaiting();
//      });
//    }
//    
//    var d = {};
//    jQuery.extend(d,getAgentInfo());
//    jQuery.extend(d,getGroupInfo());
//    jQuery.extend(d,getFormData());
//    jQuery.extend(d,getComment());
//    jQuery.extend(d,getCheckResult());
//    if (!err) {
//      updateData(d);
//      appl.noty.info("Form has been updated.");
//    } else {
//      appl.noty.error("Information not complete. please check.");
//    }
//  },
//  setFormData: function()
//  {  
//    function setScore(d) {
//      d.forEach(function(a){
//        var o = $("#score_" + a.crit_id + "_" + a.score_id);
//        if (isPresent(o)) {
//          o.prop('checked', true);
//        }
//      });
//    }
//    
//    function setComment(com) {
//      $("textarea[name=evl_comment]").val(com);
//    }
//    
//    function setCheckResult(ck) {
//      if (isPresent(ck)) {
//        $("#evl_check_comment").val(ck.comment);
//        $("#btn-check-evl span").html("Re-check");
//      } else {
//        $("#btn-check-evl span").html("Check");
//      }
//    }
//    
//    var url = Routes.evaluated_info_voice_log_path(callEvaluate.voiceId);
//    jQuery.getJSON(url,{form_id: callEvaluate.formId },function(data){
//      callEvaluate.setAgetField({id: data.agent_id, name: data.agent_name});
//      callEvaluate.setGroupField({id: data.group_id, name: data.group_name});
//      if (isPresent(data.evaluated_id)) {
//        setScore(data.criteria);
//        setComment(data.comment);
//        setCheckResult(data.check_result);
//        callEvaluate.buttonFor('evaluated');
//      } else {
//        callEvaluate.buttonFor('new');
//        callEvaluate.disableForm(false);
//      }
//    });
//  },
//  setAgetField: function(a)
//  {
//    if (isPresent(a)) {
//      //try {
//      //  $("#evl_usr_id").select2('destroy'); 
//      //} catch(e){}         
//      $("#evl_usr_id").html($('<option>',{value: a.id, text: a.name}));
//    }
//    $("#evl_usr_id").off('change').on('change',function(){
//      var o = $("option:selected",this).val();
//      callEvaluate.changeAgentGroup(o);
//    });
//    appl.autocomplete.usersSelect("#evl_usr_id");
//  },
//  setGroupField: function(a)
//  {
//    if (isPresent(a)) {
//      //try {
//      //  $("#evl_group_id").select2('destroy');
//      //} catch(e) {}      
//      $("#evl_group_id").html($('<option>',{value: a.id, text: a.name}));
//    }
//    appl.autocomplete.groupsSelect("#evl_group_id");
//  },
//  changeAgentGroup: function(id){
//    var url = Routes.get_group_user_path({id: id});
//    jQuery.get(url,function(data){
//      if (isPresent(data)) {
//        callEvaluate.setGroupField(data);
//      }      
//    });
//  },
//  showMoreInfo: function(){
//    $("#btn-more-info").css("display","none");
//    jQuery.get(Routes.evaluation_more_info_voice_log_path({id: callEvaluate.voiceId}), function(data){
//      var t = appl.getHtmlTemplate("#more-info-template");
//      $("#box-more-info div").html(t(data));
//    });
//  },
//  hideMoreInfo: function(){
//    $("#btn-more-info").css("display","block");
//    $("#box-more-info div").html("");
//  },
//  remove: function()
//  {
//    bootbox.confirm("Are you sure to delete this evaluation?", function(result) {
//      if (result){
//        var url = Routes.remove_evaluation_voice_log_path(callEvaluate.voiceId);
//        jQuery.get(url,{form_id: callEvaluate.formId },function(){
//          appl.noty.info("Deleting, please wait to refresh page.");
//          window.location.reload();
//        });
//      } else {
//        appl.noty.info("Cancelled delete."); 
//      }
//    });
//  },
//  setCurrentForm: function()
//  {
//    function hideForm() {
//      $("#box-oper-info").css("visibility","hidden");
//      $("#box-evaluation-form").css("visibility","hidden");
//      $("#box-summary-comment").css("visibility","hidden");
//      $("#box-more-info").css("visibility","hidden");
//      $("#box-noform").css("display","block");
//    }
//    function showForm() {
//      $("#box-oper-info").css("visibility","visible");
//      $("#box-evaluation-form").css("visibility","visible");
//      $("#box-summary-comment").css("visibility","visible");
//      $("#box-more-info").css("visibility","visible");
//      $("#box-noform").css("display","none");
//    }
//    var o = $("select[name=evaluation_form] option:selected");
//    if (o.val() == undefined) {
//      hideForm();
//      callEvaluate.formId = 0;
//    } else {
//      showForm();
//      callEvaluate.formId = parseInt(o.val());
//    }
//  },
//  disableForm: function(v)
//  {
//    var o = $(".panel-evaluation .evl-form");
//    if (v) {
//      o.find('input').attr('disabled', 'disabled');
//      o.find('select').attr('disabled', 'disabled');
//      o.find('textarea').attr('disabled', 'diabled');
//    } else {
//      o.find('input').removeAttr('disabled');
//      o.find('select').removeAttr('disabled');
//      o.find('textarea').removeAttr('disabled');
//    }
//  },
//  buttonFor: function(a)
//  {
//    var bsave = $("#btn-save-evl");
//    var bedit = $("#btn-edit-evl");
//    var bchek = $("#btn-check-evl");
//    var bcanc = $("#btn-cancel-evl");
//    var bremv = $("#btn-remove-evl");
//    var bcalc = $("#btn-calc-evl");
//    //init
//    bsave.css("display","none");
//    bedit.css("display","none");
//    bchek.css("display","none");
//    bcanc.css("display","none");
//    bremv.css("display","none");
//    bcalc.css("display","none");
//    if (a == 'evaluated') {
//      bedit.css("display","inline-block");
//      bchek.css("display","inline-block");
//      bremv.css("display","inline-block");
//      bcalc.css("display","inline-block");
//      callEvaluate.disableForm(true);
//    } else if (a == 'edit') {
//      bcanc.css("display","inline-block");
//      bsave.css("display","inline-block");
//      callEvaluate.disableForm(false);
//    } else {
//      bsave.css("display","inline-block");
//      callEvaluate.disableForm(true);
//    }
//  },
//  checkDialog: function()
//  {
//    var fnCorrect = function(a){
//      var url = Routes.check_result_voice_log_path(callEvaluate.voiceId);
//      jQuery.get(url,{ form_id: callEvaluate.formId, checked_result: 'correct', comment: a },function(){
//        appl.noty.info("Data has been updated.");  
//      });
//    }
//    
//    var fnWrong = function(a){
//      $("#evl_check_result").val("W");
//      $("#evl_check_comment").val(a);
//      callEvaluate.buttonFor('edit');
//    }
//
//    var opts = {
//      title: 'Check Evaluations',
//      message: "<div><label>Comment</label><textarea class=\"form-control\">" + $("#evl_check_comment").val() + "</textarea></div>",
//      buttons: {
//        correct: {
//          label: 'Correct',
//          className: 'btn-success',
//          callback: function(){
//            var cm = $(this).find('textarea').val();
//            fnCorrect(cm);
//          }
//        },
//        wrong: {
//          label: 'Wrong',
//          className: 'btn-danger',
//          callback: function(){
//            var cm = $(this).find('textarea').val();
//            fnWrong(cm);
//          }
//        },
//        cancel: {
//          label: 'Cancel',
//          className: 'btn-default',
//          callback: function(){ }
//        }
//      }
//    }
//    bootbox.dialog(opts);
//  },
//  showHideScoreDescription: function()
//  {
//    var s = (Cookies.get("show_score_desc") == "true");
//    if(s){
//      $(".item-description").css("display","block");
//      $("#fd-show-description").val("false").html("Hide Description").removeClass('btn-primary').addClass('btn-default');
//    } else {
//      $(".item-description").css("display","none");
//      $("#fd-show-description").val("true").html("Show Description").removeClass('btn-default').addClass('btn-primary');
//    }
//  },
//  init: function()
//  {
//    function setButtons() {
//      $("select[name=evaluation_form]").off('change').on('change',function(){
//        callEvaluate.setCurrentForm();
//        callEvaluate.loadForm();
//      });
//      $("#btn-save-evl").off('click').on('click',function(){
//        callEvaluate.update();
//      });
//      $("#btn-edit-evl").off('click').on('click',function(){
//        callEvaluate.buttonFor('edit');
//      });
//      $("#btn-cancel-evl").off('click').on('click',function(){
//        $("#evl_check_result").val(""); // clear check result
//        callEvaluate.buttonFor('evaluated');
//      });
//      $("#btn-check-evl").off('click').on('click',function(){
//        callEvaluate.checkDialog();  
//      });
//      $("#btn-remove-evl").off('click').on('click',function(){
//        callEvaluate.remove();
//      });
//      $("#btn-more-info").off('click').on('click',function(){
//        callEvaluate.showMoreInfo();
//      });
//      $("#btn-calc-evl").off('click').on('click',function(){
//        jQuery.getJSON(Routes.recalc_score_voice_log_path(callEvaluate.voiceId),{ form_id: callEvaluate.formId });  
//      });
//      $("#fd-show-description").off('click').on('click',function(){
//        Cookies.set("show_score_desc",$(this).val());
//        callEvaluate.showHideScoreDescription();
//      });
//    }
//    
//    function initId() {
//      callEvaluate.voiceId = callEvaluate.voiceId || gon.params.id;
//    }
//    
//    initId();
//    callEvaluate.setCurrentForm();
//    callEvaluate.loadForm();
//    callEvaluate.showEvaluatedScore();
//    setButtons();
//  }
//}