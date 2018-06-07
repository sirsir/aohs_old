var fnEdit = {
  __MAX_RAISE_DOCS: 3,
  
  checkItemCount: function()
  {
    $(".block-question-answer").each(function(){
      var o = $(this);
      var a = $("input.quest_select[value=\"true\"]",o);
      var c = 0, idx=1;
      a.each(function(){
        c = c + parseInt($(".td-score",$(this).parent().parent()).html());
        $("input.quest_orderno",$(this).parent()).val(idx);
        idx++;
      });
      $("#rw-group-id-"+ o.attr("data-group-id") +" .fd-item-cnt").html(a.length);
      $("#rw-group-id-"+ o.attr("data-group-id") +" .fd-item-max-score").html(c);
    });
  },
  
  checkUncheckTbl: function()
  {
    $("input.quest_group_select").each(function(){
      var o = $(this);
      var p = o.parent();
      if (o.val() == "true") {
        $(".btn-selected",p).removeClass("btn-hide");
        $(".btn-unselect",p).addClass("btn-hide");
        $(".fd-item-cnt",p.parent()).css("visibility","visible");
        $(".fd-item-max-score",p.parent()).css("visibility","visible");
      } else {
        $(".btn-unselect",p).removeClass("btn-hide");
        $(".btn-selected",p).addClass("btn-hide");
        $(".fd-item-cnt",p.parent()).css("visibility","hidden");
        $(".fd-item-max-score",p.parent()).css("visibility","hidden");
        /* uncheck child */
        $("#question-group-id-" + p.closest('tr').attr("data-group-id")).each(function(){
          $("input.quest_select",$(this)).val("false");
        });
      }
    });
    $("input.quest_select").each(function(){
      var o = $(this);
      var p = o.parent();
      if (o.val() == "true") {
        $(".btn-selected",p).removeClass("btn-hide");
        $(".btn-unselect",p).addClass("btn-hide");
      } else {
        $(".btn-unselect",p).removeClass("btn-hide");
        $(".btn-selected",p).addClass("btn-hide");
      }
    });
    fnEdit.checkItemCount();
    fnEdit.updateCateInfo();
  },
  
  updateCateInfo: function()
  {
    var cntAll = 0, cntSel = 0, acScore = 0, itemCnt = 0, idx = 1;
    $("#block-category table tr").each(function(){
      var o = $(this);
      if ($("input.quest_group_select",o).val() == "true") {
        cntSel++;
        $("input.quest_group_orderno",o).val(idx++);
        itemCnt = itemCnt + parseInt($(".fd-item-cnt",o).text());
        acScore = acScore + parseInt($(".fd-item-max-score",o).text());
      }
      cntAll++;
    });
    $("#fd-cate-count-seleted").html(cntSel);
    $("#fd-items-count-seleted").html(itemCnt);
    $("#fd-items-total-score").html(acScore);
  },
  
  validateForm: function()
  {
    
    function validCategegory(){
      var err = false;
      /* required group */
      var b = parseInt($("#fd-cate-count-seleted").text());
      if (b <= 0) {
        $("#fd-cate-count-seleted").addClass('has-error');
        err = true;
      } else {
        $("#fd-cate-count-seleted").removeClass('has-error');
      }
      /* all selected must have weighted and items */
      $("#block-category table tbody tr").each(function(){
        var o = $(this);
        o.removeClass('has-error');
        if ($("input.quest_group_select",o).val() == "true")  {
          if(parseInt($("input.question_group_weight",o).val()) <= 0){
            o.addClass('has-error');
            err = true;
          } else if (parseInt($(".fd-item-cnt", o).text()) <= 0) {
            o.addClass('has-error');
            err = true;
            //console.log('b');
          } else {
            o.removeClass('has-error');
          }
        }
      });
      return err;
    }
    
    function validateRule(){
      var err = false, cnt = 0;
      $("#rule-list tbody tr").each(function(){
        cnt++;
        var w = $("input[name=\"rule_condition[]\"]",$(this));
        var t = (jQuery.trim(w.val())).replace(/ +/g,'').toUpperCase();
        if((new RegExp(/(\w{1,20})(>|<|=)(\d+)/)).test(t)){
          $(this).removeClass('has-error');
        } else {
          err = true;
          $(this).addClass('has-error');
        }
        w.val(t);
      });
      if(cnt <=0 ){ err = false; }
      return err;
    }
    
    fnEdit.checkItemCount();
    fnEdit.updateCateInfo();
    if(validCategegory() || validateRule()){
      // true if error
      appl.noty.error("Some field are invalid.");
      return false;
    } else {
      appl.dialog.showWaiting();
      return true;
    }
  },
  
  reloadQuestionDialogEvent: function()
  {
    var o = $("#dialog-addcate");
    var iframe = $("iframe",o).contents();
    iframe.find("#btn-cancel-dialog").click(function(){
      $("#dialog-addcate").css("display","none");
      fnEdit.updateQuestion();
      fnEdit.updateCateInfo();
      $("#dialog-addcate iframe").removeAttr("src");
    });
  },
  
  updateQuestion: function()
  { 
    jQuery.get(Routes.group_and_questions_evaluation_plan_path(gon.params.id),function(data){
      var foundChange = false;
      if(data.question_groups !== undefined){
        var ghtm = appl.getHtmlTemplate("#template-cate-row");
        var gphtm = appl.getHtmlTemplate("#template-quest-parent");
        var qhtm = appl.getHtmlTemplate("#template-quest-row");
        data.question_groups.forEach(function(g){
          var og = $("#rw-group-id-" + g.id);
          if(og.length > 0){
            // found
          } else {
            // new
            $("#block-category tbody").append(ghtm(g));
            $("#block-question").append(gphtm(g));
            foundChange = true;
          }
          if(g.questions !== undefined){
            g.questions.forEach(function(qu){
              var opg = $("#question-group-id-" + g.id);
              if(opg.length > 0){
                var oq = $("#rw-question-id-" + qu.id,opg);
                if(oq.length <= 0){
                  $("table tbody",opg).append(qhtm(qu));
                  foundChange = true;
                } else {
                  $("td.td-title",oq).html(qu.title);
                  $("td.td-ans-type",oq).html(qu.answer_type);
                  $("td.td-score",oq).html(qu.max_score);
                }
              }
            });
          }
        });
      }
      if(foundChange){
        fnEdit.init();
      }
    });
  },
  
  addQuestionCategory: function()
  {
    function openDialog(){
      var o = $("#dialog-addcate");
      o.css("display","block");
      var h = $("div.panel-form").height();
      o.height(h);
      $("iframe",o).height(h);
      $("iframe",o).attr("src",Routes.new_evaluation_question_path() + "?lyt=blank");
      var iframe = $("iframe",o).contents();
      iframe.find("#btn-cancel-dialog").click(function(){
        $("#dialog-addcate").css("display","none");
        fnEdit.updateQuestion();
      });
    } 
    openDialog();
  },
  
  editQuestionCategory: function(id)
  {
    function openDialog(id){
      var o = $("#dialog-addcate");
      o.css("display","block");
      var h = $("div.panel-form").height();
      o.height(h);
      $("iframe",o).height(h);
      $("iframe",o).attr("src",Routes.edit_evaluation_question_path(id) + "?lyt=blank");
      var iframe = $("iframe",o).contents();
      iframe.find("#btn-cancel-dialog").click(function(){
        $("#dialog-addcate").css("display","none");
        fnEdit.updateQuestion();
      });
    }
    openDialog(id);
  },
  
  init: function(){
        
    function initTable() {
      $("#block-category table tbody tr a.btn-show-question").on('click',function(){
        var o = $(this).closest('tr');
        var i = o.attr("data-group-id");
        $(".block-question-answer").css("display","none");
        $("#question-group-id-"+i).css("display","block");
        $("#block-category table tbody tr").removeClass('row_active');
        o.addClass('row_active');
      });
      $("#block-category input.question_group_weight").on('blur keypress',function(){
        fnEdit.updateCateInfo();
      });
      $("#block-category button.btn-move-up, #block-question button.btn-move-up").on('click',function(){
        var thR = $(this).closest('tr');
        var prR = thR.prev();
        if (prR.length) {
          prR.before(thR);
        }
      });
      $("#block-category button.btn-move-down, #block-question button.btn-move-down").on('click',function(){
        var thR = $(this).closest('tr');
        var nxR = thR.next();
        if (nxR.length) {
          nxR.after(thR);
        }
      });
      fnEdit.checkUncheckTbl();
      fnEdit.updateCateInfo();
    }
    
    function initButton() {
      $("#block-category .btn-selected").off('click').on('click',function(){
        $("input.quest_group_select",$(this).parent()).val("false");
        fnEdit.checkUncheckTbl();
      });
      $("#block-category .btn-unselect").off('click').on('click',function(){
        $("input.quest_group_select",$(this).parent()).val("true");
        fnEdit.checkUncheckTbl();
      });
      $("#block-question .btn-selected").off('click').on('click',function(){
        $("input.quest_select",$(this).parent()).val("false");
        fnEdit.checkUncheckTbl();
      });
      $("#block-question .btn-unselect").off('click').on('click',function(){
        $("input.quest_select",$(this).parent()).val("true");
        fnEdit.checkUncheckTbl();
      });
      $("#block-question .btn-quest-edit").off('click').on('click',function(){
        var id = $(this).closest('tr').attr("data-question-id");
        fnEdit.editQuestionCategory(id);
      });
      var xsel = $("#form_rule").select2({
        minimumResultsForSearch: Infinity
      });
      $("#btn-add-rule").on('click',function(){
        var o = $("option:selected", xsel);
        if(o.val().length > 0){
          var htm = appl.getHtmlTemplate("#template-rule-row");
          var found = 0;
          $("#rule-list tbody tr input[name=\"rule_name[]\"]").each(function(){
            var p = $(this);
            if(p.val() == o.val()){
              found++;
            }
          });
          if(found <= 0){
            $("#rule-list tbody").append(htm({ title: o.text(), value: o.val() }));
          } else {
            appl.noty.info("This rule already added.");
          }
          $("button.btn-remove-rule").off('click').on('click',function(){
            $(this).closest('tr').remove();  
          });
        }
      });
      $("button.btn-remove-rule").off('click').on('click',function(){
        $(this).closest('tr').remove();  
      });
      $("button#btn-add-category").off('click').on('click',function(){
        fnEdit.addQuestionCategory();  
      });
    }
    
    function initForm() {
      $("form#edit_evaluation_plan_" + gon.params.id).off('submit').on('submit',function(){
        return fnEdit.validateForm();  
      });
      $('select.select-call-cate').multiselect({
        buttonWidth: '60%'
      });
    }
    
    initTable();
    initButton();
    initForm();
  }
};

jQuery(document).on('ready page:load',function(){ fnEdit.init(); });
