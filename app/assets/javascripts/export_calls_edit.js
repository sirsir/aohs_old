var fnTaskEdit = {
  MAXCONS: 10,
  htmCond: null,
  ds: {
    conds: []
  },
  openCondDialog: function(id)
  {
    function getHour(v) {
      var hrs = [];
      var a = v.replace(" ","").split(",");
      
      function correntHr(x) {
        return (x > 0) && (x < 24)
      }
      
      a.forEach(function(b){
        var h = null;
        if ((/^\d{1,2}$/).test(b)) {
          h = parseInt(b);
          if (h && correntHr(h)) {
            hrs.push(h);
          } else {
            hrs = false;
            return false;
          }
        } else if((/^\d{1,2}-\d{1,2}$/).test(b)) {
          h = b.split("-");
          var s = parseInt(h[0]), p = parseInt(h[1]);
          if (s && p && correntHr(s) && correntHr(p) && (s < p)) {
            hrs.push(s + "-" + p);
          } else {
            hrs = false;
            return false;
          }
        } else if(b.length <= 0){
        } else {
          hrs = false;
          return false;
        }
      });
      
      return hrs;
    }
    
    function getPhones(p) {
      var phns = [];
      var a = p.replace(" ","").split(",");
      a.forEach(function(b){
        b = b.replace(/[#-]/,"");
        if((/^\d{4,15}$/).test(b)){
          phns.push(b);
        }
      });
      return phns;
    }
    
    function getDurectionSec(s) {
      var secs = null;
      var sx = jQuery.trim(s);
      if (sx.length > 0) {
        if(parseInt(sx) > 0){
          secs = parseInt(sx);
        } else {
          secs = false;
        }
      }
      return secs;
    }
    
    function getAndValidateForm(o) {
      var conds = {};
      var err = false;
      
      var xd = $("#fd_date_range", o);
      conds.date_range = xd.val();
      
      var xh = $("#fd_hour", o);
      conds.hours = getHour(xh.val());
      if (conds.hours === false) {
        xh.closest(".form-group").addClass("has-error");
        err = true;
      } else {
        xh.closest(".form-group").removeClass("has-error");
      }
      
      var xt = $("#fd_tag option:selected", o);
      conds.tags = xt.val() || "";
      
      var xp = $("#fd_phone", o);
      conds.phones = getPhones(xp.val());
      if (conds.phones == false) {
        xp.closest(".form-group").addClass("has-error");
        err = true;
      } else {
        conds.phones = conds.phones.join(", ");
        xp.val(conds.phones);
        xp.closest(".form-group").removeClass("has-error");
      }
      
      var xc = $("#fd_cd option:selected", o);
      conds.call_direction = xc.val();
      
      var xf = $("#fd_from",o);
      conds.duration_from = getDurectionSec(xf.val());
      if (conds.duration_from == false) {
        xf.closest(".form-group").addClass("has-error");
        err = true;
      } else {
        xf.closest(".form-group").removeClass("has-error");
      }
      
      var xt = $("#fd_to",o);
      conds.duration_to = getDurectionSec(xt.val());
      if (conds.duration_to == false) {
        xt.closest(".form-group").addClass("has-error");
        err = true;
      } else {
        xt.closest(".form-group").removeClass("has-error");
      }
      
      var xm = $("#fd_remark", o);
      conds.remark = xm.val();
      
      var xi = $("#fd_id", o);
      conds.id = parseInt(xi.val());
      
      conds.err = err;
      
      return conds;
    }
    
    function drawConRow(cond) {
      var htm = appl.getHtmlTemplate("#cond-row-template");

      if ($("#cond_" + cond.id).length > 0) {
        $("#cond_" + cond.id).replaceWith(htm(cond));
      } else {
        $("#tbl-export-condition tbody").append(htm(cond));
      }
      
      $(".btn-edit-cond").off('click').on('click',function(){
        var o = $(this);
        openDialog(parseInt(o.attr("data-id")));
      });
      
      $(".btn-rem-cond").off('click').on('click',function(){
        var o = $(this);
        bootbox.confirm({
          message: "Are you sure to remove it?",
          callback: function (result) {
            if (result) {
              fnTaskEdit.ds.conds[parseInt(o.attr("data-id"))] = null;
              o.closest("tr").remove();                          
            }
          }
        });
      });    
    }
    
    function updateCond(cond) {
    
      drawConRow(cond);
      fnTaskEdit.ds.conds[cond.id] = cond;
      
      /* set string */
      $("#export_condition").val(JSON.stringify(fnTaskEdit.ds.conds));      
    }
    
    function lastCondId() {
      var n_id = 0;
      fnTaskEdit.ds.conds.forEach(function(c){
        if (n_id <= c.id){
          n_id++;
        }
      });
      return n_id;
    }
    
    function setCond(id) {
      
      var c_id = (id==undefined ? lastCondId() : id);
      var cond = fnTaskEdit.ds.conds[c_id];

      if (cond != undefined && cond != null) {
        return cond;
      } else {
        return { id: c_id }
      }
      
    }
  
    function dialogOption(id)
    {
      var opts = {
        message: fnTaskEdit.htmCond(setCond(id)),
        title: "Export Condition",
        buttons: {
          ok: {
            label: "Ok",
            className: "btn btn-primary",
            callback: function(){
              var cond = getAndValidateForm($(this));
              if (!cond.err) {
                updateCond(cond);
              }
              return !cond.err;
            }
          },
          cancel: {
            label: "Cancel",
            className: "btn btn-default",
            callback: function(){
              // nothing.
            }
          }
        }
      }
      
      return opts;
    }
    
    function openDialog(id) {
      var dialog = bootbox.dialog(dialogOption(id));
      dialog.bind('shown.bs.modal', function(){
        appl.picker.dateRange("#fd_date_range");
        appl.autocomplete.callTagsSelect("#fd_tag");
      });
    }
    
    openDialog(id);
  },
  
  init: function()
  {
    
    function clearValidateMsg() {
      $("#gp-name").find('.help-block').remove();
      $("#gp-name").closest('.form-group').removeClass('has-error');
      $("#gp-category").find('.help-block').remove();
      $("#gp-category").closest('.form-group').removeClass('has-error');
      $("#gp-filename").find('.help-block2').remove();
      $("#gp-filename").closest('.form-group').removeClass('has-error');
    }
    
    function setValidateMsg(errors) {
      if (errors.name) {
        $("#gp-name").closest('.form-group').addClass('has-error');
        $("#gp-name").append($("<span>",{ class: 'help-block', text: errors.name.join(",") }));
      }
      if (errors.category) {
        $("#gp-category").closest('.form-group').addClass('has-error');
        $("#gp-category").append($("<span>",{ class: 'help-block', text: errors.category.join(",") }));
      }
      if (errors.filename) {
        $("#gp-filename").closest('.form-group').addClass('has-error');
        $("#gp-filename").append($("<span>",{ class: 'help-block2', text: jQuery.unique(errors.filename).join(",") }));
      }
    }
    
    function whenSubmitForm() {
      $("form[name=task]").on('ajax:success',function(e, data, status, xhr){
        clearValidateMsg();
        var result = jQuery.parseJSON(xhr.responseText);
        if (isPresent(result.errors)) {
          setValidateMsg(result.errors);
          appl.noty.error("Failed to update, try again.");
        } else {
          appl.noty.info("Form has been updated.");
        }
      }).on('submit',function(){
        // nothing
      });
    }
    
    function setTable() {
      function drawConRow(cond) {
        var htm = appl.getHtmlTemplate("#cond-row-template");
        
        if ($("#cond_" + cond.id).length > 0) {
          $("#cond_" + cond.id).replaceWith(htm(cond));
        } else {
          $("#tbl-export-condition tbody").append(htm(cond));
        }
        
        $(".btn-edit-cond").off('click').on('click',function(){
          var o = $(this);
          fnTaskEdit.openCondDialog(parseInt(o.attr("data-id")));
        });
        
        $(".btn-rem-cond").off('click').on('click',function(){
          var o = $(this);
          bootbox.confirm({
            message: "Are you sure to remove it?",
            callback: function (result) {
              if (result) {
                fnTaskEdit.ds.conds[parseInt(o.attr("data-id"))] = null;
                o.closest("tr").remove();                          
              }
            }
          });
        });    
      }
      fnTaskEdit.ds.conds = JSON.parse($("#export_condition").val());
      fnTaskEdit.ds.conds.forEach(function(cond){
        drawConRow(cond); 
      });
    }
    
    $("#btn-newcond").on('click',function(){
      fnTaskEdit.openCondDialog();
    });

    fnTaskEdit.htmCond = appl.getHtmlTemplate("#cond-dialog-template");
    setTable();
    whenSubmitForm();
  }
}

jQuery(document).on('ready page:load',function(){fnTaskEdit.init();});