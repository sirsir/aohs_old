var _fnMnt = { 
  pickerInit: function(){
    
    function inputDateTimeRangePicker(){
      var drange = {
        'Today': [moment().startOf('day'), moment().endOf('day')],
        'Yesterday': [moment().subtract('days', 1).startOf('day'), moment().subtract('days', 1).endOf('day')],
        'This week': [moment().startOf('week').startOf('day'), moment().endOf('day')],
        'Last 7 Days': [moment().subtract('days', 6).startOf('day'), moment().endOf('day')],
        'Last 30 Days': [moment().subtract('days', 29).startOf('day'), moment().endOf('day')],
        'This Month': [moment().startOf('month').startOf('day'), moment().endOf('month').endOf('day')],
        'Last Month': [moment().subtract('month', 1).startOf('month').startOf('day'), moment().subtract('month', 1).endOf('month').endOf('day')]
      };
      
      var opts = {
        locale: {
          format: appl.cof.moment.fmt_dt,
        },
        ranges: drange,
        startDate: moment().startOf('day'),
        endDate: moment(),
        timePicker: true,
        timePicker24Hour: true,
        timePickerIncrement: 1,
        dateLimit: {
          days: 180
        }
      };
      
      $("input.input-date-rank").each(function(){
        var o = $(this);
        if(o.attr("allow-blank") == "true"){
          o.daterangepicker(jQuery.extend({ autoUpdateInput: false }, opts));
          o.on('apply.daterangepicker', function(ev, picker) {
            $(this).val(picker.startDate.format(appl.cof.moment.fmt_dt) + ' - ' + picker.endDate.format(appl.cof.moment.fmt_dt));
          });
          o.on('cancel.daterangepicker', function(){
            $(this).val('');
          });
        } else {
          o.daterangepicker(opts);
        }
      });
    }
    
    function inputDatePicker()
    {
      var opts = {
        locale: {
          format: appl.cof.moment.fmt_d
        },
        timePicker: false
      };
      try {
        $("input.date-picker").datetimepicker(opts); 
      } catch(e){
        console.log(e);
      }
      
    }
    
    inputDateTimeRangePicker();
    inputDatePicker();
  },
  
  resetButtonInit: function()
  {
    
    $("button.btn-reset-form").on('click',function(){
      $(this).closest("form").clearForm();
    });
  },
  
  init: function()
  {
    function bindRowActions()
    {
      
      var isMatchActionName = function(a, b){
        return a == b;
      }
      
      $(".doact div").on('click',function(){ 
        var o = $(this);
        var a = o.attr("act"), t = o.attr("href");
        if (isMatchActionName(a,"show")){
          appl.redirectTo(t);
        } else if (isMatchActionName(a,"edit")){
          appl.redirectTo(t);
        } else if (isMatchActionName(a,"delete")){
          appl.dialog.deleteConfirm(t);
        } else if (isMatchActionName(a,"undelete")){
          appl.dialog.undeleteConfirm(t);
        }
      });

    }
    
    function highLightSelectedRow()
    {
      $('table.table-mnt').on('click','tbody tr',function(event){
        $(this).addClass('highlight').siblings().removeClass('highlight');
      }); 
    }
    
    function bindFilterButton()
    {
      
      var toggleFilter = function()
      {
        var t = $(this);
        var o = $("div.mnt-filter");
        if(o.css("display") == "none"){
          o.css("display","block");
          t.addClass("active");
        } else {
          o.css("display","none");
          if (!t.hasClass("filter-active")) {
            t.removeClass("active");
          }
        }
      }
      
      $(".navbar-mnt .filter-button").on("click",toggleFilter);
    }

    function isFoundMaTable()
    {
      return $("table.table-mnt").length;
    }
    
    function helpDialog()
    {
      $("a.btn-help-dialog").on('click',function(){
        appl.dialog.helpDialog($(this).attr("data-topic"));
      });
    }
    
    /* init */
    appl.mnt.pickerInit();
    appl.mnt.resetButtonInit();
    bindFilterButton();
    helpDialog();
    if (isFoundMaTable()){
      bindRowActions();
      highLightSelectedRow();
    }
    
  }
}

jQuery.extend(appl.mnt,_fnMnt);
jQuery(document).on('ready page:load',appl.mnt.init);