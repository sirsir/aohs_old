//= require 'cropper'
var cropObj;
var fn_user_edit = {
  
  init: function(){
    function datePickers(){
      var dOpts = {
        format: 'YYYY-MM-DD',
        showClear: true,
        icons: { next: 'fa fa-chevron-right',
          previous: 'fa fa-chevron-left',
          clear: 'fa fa-trash',
          close: 'fa fa-remove'
        }
      };
      $('#user_joined_date').datetimepicker(dOpts);
      $('#user_dob').datetimepicker(dOpts);       
    }
    datePickers();
    $("#add_group").click(function(){
      var o = $("#group option:selected");
      fn_user_edit.updateGroupMembers(o.val());
    });
    fn_user_edit.updateGroupMembers();
    $("input[name=chb-unknown], input[name=chb-all-groups]").click(function(){
      var o = $(this);
      $.getJSON(Routes.update_attr_user_path({id: gon.params.id}),{
        attr_id: o.prop("value"),
        attr_value: o.prop("checked")
      });
    });
    $("input[name=reset_password]").on("click",function(){
      console.log($(this).prop('checked'));
      if ($(this).prop('checked')) {
        $("#user_password").attr("disabled","disabled");
        $("#user_password_confirmation").attr("disabled","disabled");      
      } else {
        $("#user_password").removeAttr("disabled");
        $("#user_password_confirmation").removeAttr("disabled");  
      }
    });
    $("#btn-change-picture").on('click',function(){
      $(".edit-image").css('visibility','visible');
      $("#box-upload").css("display","inline-block");
      $("#box-crop-avartar").css("display","none");
      $("#btn-update-picture").attr("disabled","disabled");
    });
    $("#btn-cancel-picture").on('click',function(){
      $(".edit-image").css('visibility','hidden'); 
    });
    $("#btn-update-picture").on('click',function(){
      var cObj = cropObj.cropper('getCroppedCanvas');
      var dataUri = cObj.toDataURL();
      var imForm = new FormData();
      imForm.append('data_uri', dataUri);
      imForm.append('authenticity_token', appl.postKeyString());
      $.ajax({
        url: Routes.upload_image_user_path({id: gon.params.id}),
        data: imForm,
        processData: false,
        contentType: false,
        type: 'POST',
        success: function(result){
          $(".edit-image").css('visibility','hidden');
          $("#avatar-box").attr("src",Routes.avatar_user_path({id: gon.params.id}) + "?t=" + (new Date()).getTime());
          appl.noty.info("Picture has been updated.");
        },
        error: function(){
          appl.noty.error("Error, please try again");
        }
      });
    });
    $("input[name=list_location]").on('click',function(){
      var sites = [];
      $("input[name=list_location]:checked").each(function(){
        sites.push($(this).val());  
      });
      $.getJSON(Routes.update_attr_user_path({id: gon.params.id}),{
        attr_id: $("#user_attr_location").val(),
        attr_value: sites.join("|")
      });
    });
  },
  updateGroupMembers: function(group_id,act){
    var g = group_id || 0;
    var a = act || "add";
    var url = Routes.update_member_group_members_path({
      group_id: g, user_id: gon.params.id, act: a
    });
    jQuery.getJSON(url,function(data){
      var ht_tem = appl.getHtmlTemplate("#tbl-template"); 
      var htm = ht_tem(data);
      $("#group_member").html(htm);
      $(".btn-delete-link").click(function(){
        var o = $(this);
        fn_user_edit.updateGroupMembers(o.attr("data-delete-id"),"delete");
      });
    });
  },
  experienceInfo: function()
  {
    var ds = [];
    
    function getTemplate() {
      return appl.getHtmlTemplate("#exp_list_template");
    }
    
    function sumWorkLength() {
      function dspYM(m) {
        var yx = Math.floor(m/12), mx = m%12, t = "";
        if (yx > 0) { t = yx + " years "; }
        if (mx > 0) { t = t + mx + " months "; }
        return t;
      }
      var m = 0;
      ds.forEach(function(d){ m = m + d.length_of_work });
      return dspYM(m);
    }
    
    function showList()
    {
      var url = Routes.list_user_user_experiences_path({ user_id: gon.params.id });
      jQuery.get(url,function(data){
        ds = data;
        var t = getTemplate();
        $("#experience-list tbody").html(t({ experiences: data }));
        $(".btn-exp-edit").off('click').on('click',function(){
          var o = $(this);
          var edu = ds[parseInt(o.attr("data-no"))-1];
          expDialog(edu);
        });
        $(".btn-exp-delete").off('click').on('click',function(){
          var o = $(this);
          removeExp(parseInt(o.attr("data-id")));
        });
        $("#fl-tt-exprience").html(sumWorkLength());
      });
    }
    
    function removeExp(id)
    {
      bootbox.confirm("Are you sure to delete this?",function(result){
        if(result){
          var url = Routes.delete_user_user_experience_path(gon.params.id,id);
          jQuery.post(url,{ authenticity_token: window._frmTk },function(){
            showList();
          });          
        }  
      });
    }
    
    function ymToMonths(y,m)
    {
      return (m + (y * 12));
    }
    
    function submitForm(obj)
    {
      function correctInfo(edu)
      {
        var o = $(obj);

        if (isEmpty(exp.position)) {
          $("input[name=exp_position]",o).parent().addClass("has-error");
          return false;
        }
        $("input[name=exp_position]",o).parent().removeClass("has-error");
        
        if (isEmpty(exp.company)) {
          $("input[name=exp_company]",o).parent().addClass("has-error");
          return false;
        }
        $("input[name=exp_company]",o).parent().removeClass("has-error");
        
        return true;
      }
      
      function getFields()
      {
        var exp = {};
        exp.position = $("input[name=exp_position]",o).val();
        exp.company = $("input[name=exp_company]",o).val();      
        exp.length_of_work = ymToMonths(parseInt($("select[name=exp_len_year] option:selected",o).val()),parseInt($("select[name=exp_len_month] option:selected",o).val()));
        $("input[name=exp_length_of_work]",o).val(exp.length_of_work);        
        return exp;
      }
      
      var o = $(obj), exp = getFields();
      if (correctInfo(exp)) {
        $("form",o).trigger("submit");
        showList();
        return true;
      } else {
        return false;
      }
    }

    function expDialog(data)
    {
      var exp = data || {};
      var t = appl.getHtmlTemplate("#exp_form_template");
      var opts = {
        title: "Work Experience",
        message: t({exp: exp}),
        animate: false,
        buttons: {
          cancel: {
            label: "Cancel",
            className: "btn-default",
            callback: function(){}
          },
          ok: {
            label: "OK",
            className: "btn-primary",
            callback: function(){
              return submitForm(this);
            }
          }
        }
      }
      bootbox.dialog(opts);
    }
    
    $("#btn-add-exp").on('click',function(){
      expDialog();
    });
    showList();
  },
  educationInfo: function()
  {  
    var ds = [];
    
    function eduTemplate() {
      return appl.getHtmlTemplate("#edu_list_template");
    }
    
    function showList()
    {
      var url = Routes.list_user_user_educations_path({ user_id: gon.params.id }); 
      jQuery.get(url,function(data){
        ds = data;
        var t = eduTemplate();
        $("#education-list tbody").html(t({ educations: data }));
        $(".btn-edu-edit").off('click').on('click',function(){
          var o = $(this);
          var edu = ds[parseInt(o.attr("data-no"))-1];
          eduDialog(edu);
        });
        $(".btn-edu-delete").off('click').on('click',function(){
          var o = $(this);
          removeEdu(parseInt(o.attr("data-id")));
        });
      });
    }
    
    function removeEdu(id)
    {
      bootbox.confirm("Are you sure to delete this?",function(result){
        if(result){
          var url = Routes.delete_user_user_education_path(gon.params.id,id);
          jQuery.post(url,{ authenticity_token: window._frmTk },function(){
            showList();
          });
        }
      });
    }
    
    function submitForm(obj)
    {  
      function correctInfo(edu)
      {
        var o = $(obj);
        
        if (isEmpty(edu.institution)){
          $("input[name=edu_inst]",o).parent().addClass("has-error");
          return false;
        }
        $("input[name=edu_inst]",o).parent().removeClass("has-error");
        
        if (isEmpty(edu.subject)) {
          $("input[name=edu_subj]",o).parent().addClass("has-error");
          return false;
        }
        $("input[name=edu_subj]",o).parent().removeClass("has-error");
        
        return true;
      }
      
      function getFields()
      {
        var edu = {};
        edu.institution = getVal($("input[name=edu_inst]",o).val());
        edu.subject = getVal($("input[name=edu_subj]",o).val());
        edu.year_passed = parseInt($("input[name=edu_year_passed]",o).val());        
        return edu;
      }
      
      var o = $(obj), edu = getFields();
      if (correctInfo(edu)) {
        $("form",o).trigger("submit");
        showList();
        return true;
      } else {
        return false;
      }
    }
    
    function eduDialog(data)
    {
      var edu = data || {};
      var t = appl.getHtmlTemplate("#edu_form_template");
      var opts = {
        title: "Education",
        message: t({edu: edu}),
        animate: false,
        buttons: {
          cancel: {
            label: "Cancel",
            className: "btn-default",
            callback: function(){}
          },          
          ok: {
            label: "OK",
            className: "btn-primary",
            callback: function(){
              return submitForm(this);
            }
          }
        }
      };
      bootbox.dialog(opts);
    }
    
    $("#btn-add-edu").on('click',function(){
      eduDialog();
    });
    showList();
  }
};

jQuery(document).on('ready page:load',function(){
  fn_user_edit.init();
  fn_user_edit.educationInfo();
  fn_user_edit.experienceInfo();
});

var cropx;
Dropzone.options.frImgupload = {
  acceptedFiles: "image/*",
  init: function() {
    var _this = this;
    this.on("success", function(file, result) {
      $("#avatar-crop-box").attr("src",result.srcbase64);
      if (cropObj) {
        cropObj.cropper('destroy');
      }
      cropObj = $('#avatar-crop-box').cropper({
        aspectRatio: 1/1,
        autoCropArea: 1.0,
        strict: true,
        guides: true,
        highlight: false,
        dragCrop: false,
        cropBoxMovable: true,
        cropBoxResizable: false
      });
      $("#box-upload").css("display","none");
      $("#box-crop-avartar").css("display","inline-block");
      $("#btn-update-picture").removeAttr("disabled");
      _this.removeAllFiles();
    });
    this.on("error",function(file,responseText){
      _this.removeAllFiles();  
    });
  }
};