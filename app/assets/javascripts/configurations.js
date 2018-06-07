//= require 'mcColorPicker'

fnConfig = {
  initProgram: function()
  {
    var TBID = "#table-program-settings";
    
    function rowEvents()
    {
      
      $(TBID+" .btn-pg-remove").off('click').on('click',function(){
        $(this).closest("tr").remove();
      });
      
      $(TBID+" input[type=\"text\"").off('blur').on('blur',function(){
        var o = $(this);
        if (o.val().length <= 0){
          o.val(o.attr("data-original-value"));
        }
        if (o.val() != o.attr("data-original-value")) {
          $(this).closest("tr").attr("data-changed","yes");
        }
      });
      
      $(TBID+" input[type=\"color\"").off('input').on('input',function(){
        var o = $(this);
        if (o.val().length <= 0){
          o.val(o.attr("data-original-value"));
        }
        if (o.val() != o.attr("data-original-value")) {
          $(this).closest("tr").attr("data-changed","yes");
        }
      });
      
    }
    
    function update()
    {
      var data = [];
      var names = [];
      var isErr = false;
      
      $(TBID+" tbody tr").each(function(){
        var o = $(this);
        o.removeAttr("data-input-error");
        var d = {
          id: o.attr("data-id") || "0",
          title: jQuery.trim($("input[name=title]",o).val()),
          bg: $("input[name=bg_color]",o).val()
        };
        if (d.title.length > 0){
          if (!names.includes(d.title)) {
            names.push(d.title);
            data.push(d);
          } else {
            o.attr("data-input-error","error");
            isErr = true;
          }
        }
      });

      if (!isErr) {
        jQuery.post(Routes.update_programs_configurations_path(),{
          authenticity_token: window._frmTk,
          data: data
        },function(){
          appl.noty.info("Data has been update. Please wait while refresh page.");
          window.location.reload();
        });
      } else {
        appl.noty.error("Dupplicate data.");
      }
      
    }

    function updateList() {
      bootbox.confirm("Are you sure update list from logs?", function(result) {
        if (result) {
          appl.dialog.showWaiting();
          jQuery.get(Routes.update_program_list_configurations_path(),function(){
            window.location.reload();  
          });
        }
      });
    }
    
    $("#btn-pg-save").on('click',function(){
      update();
    });
    $("#btn-update-list").on('click',function(){
      updateList();
    });
    
    rowEvents();
  },
  
  initModule: function()
  {
    $("button.btn-enadis-mod").each(function(){
      var o = $(this);
      var s = o.attr("data-module-status");
      if (s == "disabled") {
        o.removeClass("btn-default").addClass("btn-danger").html("Disabled");
      } else if (s == "enabled") {
        o.removeClass("btn-default").addClass("btn-success").html("Enabled");
      }
    });
    $("button.btn-enadis-mod").on('click',function(){
      var o = $(this);
      var s = o.attr("data-module-status");
      var t = o.attr("data-title");
      appl.dialog.showWaiting();
      jQuery.get(Routes.update_module_configurations_path(),{
        name: t,
        status: s
      },function(data){
        window.location.reload();  
      });
    });
  },
  
  initLocation: function()
  {
    $("#btn-lc-update").on('click',function(){
      var data = [];
      $("#table-location-settings tbody tr").each(function(){
        var o = $(this);
        var a = {
          id: $("input[name=id]",o).val(),
          name: $("input[name=title]",o).val()
        };
        data.push(a);
      });
      jQuery.post(Routes.update_locations_configurations_path(),{
        authenticity_token: window._frmTk,
        data: data
      },function(){
        appl.noty.info("Data has been update. Please wait while refresh page.");
        window.location.reload();
      });
    });  
  },
  
  initDisplayColumn: function()
  {
    $("button.btn-moveup").on('click',function(){
      var row = $(this).parents("tr:first");
      row.insertBefore(row.prev());
    });
    $("button.btn-movedown").on('click',function(){
      var row = $(this).parents("tr:first");
      row.insertAfter(row.next());
    });
    $("#btn-dc-update").on('click',function(){
      var data = [];
      $("#table-display-settings tbody tr").each(function(){
        var o = $(this);
        data.push({
          id: $("input[name=display_id]",o).val(),
          enable: $("input[name=column_enable]",o).prop("checked"),
          search_enable: $("input[name=column_searchable]",o).prop("checked")
        });
      });
      jQuery.post(Routes.update_display_columns_configurations_path(),{
        authenticity_token: window._frmTk,
        data: data          
      },function(){
        appl.noty.info("Data has been update. Please wait while refresh page.");
        window.location.reload();  
      });
    });
    $("#table-list").on('change',function(){
      appl.redirectTo(appl.mkUrl(Routes.configurations_path(),{ name: "display_tables", table: $("option:selected",this).val() }));
    });
  },
  
  init: function()
  {
    if (gon.params.name=="program") {
      fnConfig.initProgram();
    } else if (gon.params.name=="module") {
      fnConfig.initModule();
    } else if (gon.params.name=="location_info") {
      fnConfig.initLocation();
    } else if (gon.params.name=="display_tables") {
      fnConfig.initDisplayColumn();
    }
  }
}

jQuery(document).on('ready page:load',function(){ fnConfig.init(); });