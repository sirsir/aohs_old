//=require 'jQuery.extendext.min'
//=require 'doT.min'
//=require 'query-builder.min'

var fnNew = {
  MAX_CHOICES: 15,
  
  reloadGroupOption: function(selectedName){
    jQuery.getJSON(Routes.group_options_evaluation_questions_path({ select: selectedName }),function(data){
      var o = $("#evaluation_question_question_group_id");
      o.html("");
      data.forEach(function(d){
        o.append(jQuery("<option>",{ value: d[1], text: d[0], selected: (d[0] == selectedName) }));  
      });
    });
  },
  
  addGroupDialog: function(){
    function createGroup(title){
      title = title || "";
      if(title.length > 0){
        var url = Routes.create_group_evaluation_questions_path();
        jQuery.getJSON(url,{
          title: title
        },function(){
          fnNew.reloadGroupOption(title);
        });
      }
    }
    
    bootbox.prompt({
      title: "Add Group of Question",
      inputType: 'text',
      callback: function (result) {
        createGroup(result);
      }
    });
  },
  
  getAnswerType: function(){
    return $("#select-answer-type option:selected").val();  
  },
  
  checkInputType: function(type){
    var r = { isList: false, isNumber: false, isCheckBox: false };
    if((type == "radio") || (type == "checkbox") || (type == "combo")){
      r.isList = true;
      if(type == "checkbox"){
        r.isCheckBox = true;
      }
    } else if (type == "numeric"){
      r.isNumber = true;
    }
    return r;
  },
  
  showAnswers: function(){
    var type = fnNew.checkInputType(fnNew.getAnswerType());
    $("#box-choice-list").css("display","none");
    $("#box-choice-score").css("display","none");
    if(type.isList){
      $("#box-choice-list").css("display","block");
      $("input[name=\"answer_score\"]").attr("type","hidden");
    } else if(type.isNumber){
      $("input[name=\"answer_score\"]").attr("type","number");
      $("#box-choice-score").css("display","block");
    }
  },
  
  showHideAnaButton: function(){
    var type = fnNew.checkInputType(fnNew.getAnswerType());
    if(type.isList){
      $("#tbl-choice-list tbody tr").each(function(){
        var or = $(this);
        var os = $("input[name=\"answerlist_value[]\"]",or);
        if((os.val().length <= 0) || (parseInt(os.val()) === 0)){
          $(".btn-ana-config",or).prop('disabled',true);
        } else {
          $(".btn-ana-config",or).prop('disabled',false);
        }
        os.off('change').on('change',function(){
          var oi = $(this), ot = $(this).parent().closest('tr');
          console.log(oi.val());
          if((oi.val().length <= 0) || (parseFloat(oi.val()) === 0)){
            $(".btn-ana-config",ot).prop('disabled',true);
          } else {
            $(".btn-ana-config",ot).prop('disabled',false);
          }
        });
      });
    }
  },
  
  addAnswer: function(){
    function isNotMax(){
      var cnt = $("#tbl-choice-list tbody tr").length;
      return (cnt < fnNew.MAX_CHOICES);
    }
    function appendList(){
      var o = $("#tbl-choice-list");
      var t = appl.getHtmlTemplate("#template-row-inputlist");
      o.append(t());
      fnNew.initListButton(o);
    }
    if(isNotMax()){
      appendList();
      fnNew.showHideAnaButton();
    } else {
      appl.noty.error("Not allowed to add choices more than " + fnNew.MAX_CHOICES + " choices");
    }
  },
  
  validateInput: function()
  {
    var err = false;
    var type = fnNew.checkInputType(fnNew.getAnswerType());
    
    function parseScore(v){
      return appl.evaluation.scoreFormat(v);
    }
    
    function isSetValue(v){
      return !jQuery.trim(v).isEmpty();
    }
    
    function isCorrectScore(v){
      if(type.isList && type.isCheckBox){
        return (v >= -100 && v <= 100);
      } else {
        return (v >= 0 && v <= 100);
      }
    }
    
    function validScoreList(){
      var err = false, cnt = 0, labels = [];
      $("#tbl-choice-list tbody tr").each(function(){
        cnt++;
        var ot = $("input[name=\"answerlist_title[]\"]",this);
        if (!isSetValue(ot.val()) || (ot.val().length <= 1) || (jQuery.inArray(ot.val(),labels) !== -1)) {
          ot.addClass('has-error');
          err = true;
        } else {
          labels.push(ot.val());
          ot.removeClass('has-error');
        }
        var os = $("input[name=\"answerlist_value[]\"]",this);
        if (!isSetValue(os.val()) || !isCorrectScore(parseScore(os.val()))) {
          os.addClass('has-error');
          err = true;
        } else {
          os.val(parseScore(os.val()));
          os.removeClass('has-error');
        }
      });
      if (cnt <= 1) { err = true; }
      return err;
    }
    
    function validScoreNumber() {
      var ot = $("input[name=\"answer_score\"]");
      if (!isSetValue(ot.val()) || !isCorrectScore(parseScore(ot.val()))) {
        ot.addClass('has-error');
        return true;
      } else {
        ot.removeClass('has-error');
        return false;
      }
    }
    
    if(type.isList){
      err = validScoreList();
    } else if(type.isNumber){
      err = validScoreNumber();
    }
    return !err;
  },
  
  initParentFn: function(){
    try {
      window.parent.fnEdit.reloadQuestionDialogEvent();
    } catch(e){}
  },
  
  openAnaDialog: function(btn){
    
    function createTemplate(){
      /* create filters for query builder */
      var ds = jQuery.parseJSON($("#rule_data").html()), filters = [];
      Object.forEach(ds, function(ofl, txt){
        var opt = ofl.options;
        var filter = {
          id: txt,
          label: ofl.label,
          type: opt.type,
          input: opt.input,
          operators: opt.operators,
          values: opt.values
        };
        filters.push(filter);
      });
      return filters;
    }
    
    function getResult(rule){
      if(rule.condition === undefined){
        return {
          id: rule.id,
          operator: rule.operator,
          value: rule.value
        };
      } else {
        if(rule.rules !== undefined){
          var r = [];
          for(var i=0; i<rule.rules.length; i++){
            r.push(getResult(rule.rules[i]));
          }
          if(r.length > 0){
            return {
              condition: rule.condition,
              rules: r
            };
          }
        }
      }
    }
    
    function getResultFromField(){
      var rulesStr = $("input[type=\"hidden\"]",btn).val().toString();
      if(!rulesStr.isEmpty()){
        try {
          return jQuery.parseJSON(rulesStr);
        } catch(e){}
      }
      return null;
    }
    
    bootbox.dialog({
      title: "Auto Assessment Rules Setting",
      message: jQuery("<div/>",{ id: "ana-builder" }),
      closeButton: true,
      animate: false,
      size: 'large',
      buttons: {
        cancel: {
          label: "Cancel",
          className: 'btn-default'
        },
        ok: {
          label: "OK",
          className: 'btn-primary',
          callback: function(){
            var rules = $('#ana-builder',this).queryBuilder('getRules');
            if(rules !== null){
              var rs = getResult(rules);
              $("input[name=\"answerlist_ana_rules[]\"]",btn).val(JSON.stringify(rs));
              return true;
            }
            return false;
          }
        }
      }
    }).init(function(){
      $('#ana-builder',this).queryBuilder({
        filters: createTemplate(),
        conditions: ["AND"],
        allow_groups: 0
      });
      var rules = getResultFromField();
      if(rules !== null){
        $('#ana-builder',this).queryBuilder('setRules',rules);
      }
    });
  },
  
  initListButton: function(o){
    var oa, ob, oc;
    
    function toggleCommentButton(o){
      var oa = $("input",o);
      var ob = $("span",o);
      if(oa.val() == "N"){
        o.addClass("btn-success");
        oa.val("Y");
        ob.html("Yes");
      } else {
        o.removeClass("btn-success");
        oa.val("N");
        ob.html("No");
      }
    }
    
    if(o === undefined){
      oa = $("button.btn-remove-list");
      ob = $("button.btn-ana-config");
      oc = $("button.btn-comment-required");
    } else {
      oa = $("button.btn-remove-list",o);
      ob = $("button.btn-ana-config",o);
      oc = $("button.btn-comment-required",o);
    }
    oa.off('click').on('click',function(){
      var o = $(this);
      bootbox.confirm("Are you sure to remove?", function(result) {
        if(result){
          $(o).closest('tr').remove(); 
        }
      });
    });
    ob.off('click').on('click',function(){
      fnNew.openAnaDialog($(this));
    });
    oc.off('click').on('click',function(){
      toggleCommentButton($(this));
    });
  },
  
  init: function(){
    function initButton() {
      $("#btn_add_group").on('click',function(){
        fnNew.addGroupDialog();
      });
      $("#select-answer-type").on('change',function(){
        fnNew.showAnswers();
      });
      $("#btn-add-list").on('click',function(){
        fnNew.addAnswer();
      });
      $("form").on('submit',function(){
        return fnNew.validateInput();
      });
      fnNew.showHideAnaButton();
    }
    initButton();
    fnNew.showAnswers();
    fnNew.initParentFn();
    fnNew.initListButton();
    $("#evaluation_question_code_name").on('keyup keypress',function(){
      var $this = $(this), value = $this.val();
      var curPos = this.selectionStart;
      if (value.length >= 1) {
        $this.val(value.toUpperCase());
        this.selectionStart = curPos;
        this.selectionEnd = curPos;
      }
    });
  }
};

jQuery(document).on('ready page:load',function(){ fnNew.init(); });