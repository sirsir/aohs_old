Sugar.extend({
  namespaces: [Array, Date, String, Number, Object]
});

jQuery.ajaxSetup({
  statusCode: {
    401: function(){
      noty({
        layout: 'topCenter',
        text: "Account already logout.",
        type: 'information',
        timeout: 3000,
        theme: 'relax'
      });
      setTimeout(function(){
        window.location.reload();  
      },1500);
    },
    408: function(){
      noty({
        layout: 'topCenter',
        text: "Your request is timeout.",
        type: 'information',
        timeout: 3000,
        theme: 'relax'
      });
      setTimeout(function(){
        window.location.reload();  
      },1500);
    },
    500: function(){
      noty({
        layout: 'topCenter',
        text: "Something went wrong. Please try again.",
        type: 'information',
        timeout: 3000,
        theme: 'relax'
      });
      appl.dialog.hideWaiting();
    }
  }
});

moment.locale('en',{
  longDateFormat: {
    LT: 'HH:mm',
    LTS: 'HH:mm:ss',
    L: 'YYYY-MM-DD',
  },
  week: {
    dow: 1  
  }
});

var MSG = {
  DOWNLOAD_ERROR: "Your download was unsuccessfully, please try again."
};

var appl = {};
jQuery.extend(appl,{
  
  author: "",
  
  version: null,

  redirectTo: function(u){
    window.location.href = u;
  },
  
  baseUrl: function(){
    return document.location.origin;  
  },
  
  openUrl: function(url, name){
    var ourl = url;
    if(!url.startsWith('http')){
      ourl = appl.baseUrl() + ourl; 
    }
    window.open(ourl, name);
    return null; 
  },
  
  reloadPage: function(){
    window.location.reload();  
  },
  
  getHTML: function(n)
  {
    return $(n).html();
  },
  
  getHtmlTemplate: function(n)
  {
    return Handlebars.compile(this.getHTML(n));
  },
  
  hbsTemplate: function(name){
    if(appl._hbsTemplateArray === undefined){
      /* find and build html template */
      appl._hbsTemplateArray = [];
      appl._hbsTemplateTypes = ["text/template","text/x-handlebars"];
      appl._hbsTemplateTypes.forEach(function(tName){
        $("script[type=\"" + tName + "\"]").each(function(){
          appl._hbsTemplateArray.push({ id: this.id, hbs: Handlebars.compile($(this).html()) });
        });
      });
    }
    /* return template */
    name = name || null;
    if(name !== null){
      var to = appl._hbsTemplateArray.find(function(t){
        return (t.id == name);  
      });
      return (to === null ? to : to.hbs);
    }
  },
  
  mkUrl: function(url,parms)
  {
    var p = jQuery.param(parms || {});
    return [url,p].join("?");
  },
  
  fileDownload: function(url, opts)
  {
    appl.dialog.showWaiting();
    $.fileDownload(url,{
      successCallback: function(url){
        appl.dialog.hideWaiting();
      },
      failCallBack: function(url){
        appl.dialog.hideWaiting();
        appl.noty.error(MSG.DOWNLOAD_ERROR); }
    });
  },
  
  fileDownloadWithFormat: function(fnUrl, opts)
  {
    var tmpl = appl.getHtmlTemplate("#dialog_download_fileformat"); 
    var dialogOptions = {
      title: "File Download",
      animate: false,
      message: tmpl({ formats: opts })
    };
    
    var dialog = bootbox.dialog(dialogOptions);
    dialog.init(function(){
      $("button.btn-filedownload",this).on('click',function(){
        var fileType = $(this).attr("data-file-format");
        appl.dialog.showWaiting();
        $.fileDownload(fnUrl(fileType),{
          successCallback: function(url){
            appl.dialog.hideWaiting();
          },
          failCallBack: function(url){
            appl.dialog.hideWaiting();
            appl.noty.error(MSG.DOWNLOAD_ERROR); }
        });
        bootbox.hideAll();
      });
    });
  },
  
  defaultPostParams: function(){
    return {
      authenticity_token: appl.postKeyString()
    };
  },
  
  postKeyString: function()
  {
    return window._frmTk;  
  },
  
  sToms: function(s)
  {
    // sec to msec
    return (s * 1000);
  },
  
  msTos: function(ms)
  {
    // msec to sec
    return (ms/1000);
  },
  
  secToTime: function(s){
    var sec_num = parseInt(s, 10); // don't forget the second param
    var hours   = Math.floor(sec_num / 3600);
    var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
    var seconds = sec_num - (hours * 3600) - (minutes * 60);
    if (hours   < 10) {hours   = "0"+hours;}
    if (minutes < 10) {minutes = "0"+minutes;}
    if (seconds < 10) {seconds = "0"+seconds;}
    return minutes+':'+seconds;
  },
  
  timeToSec: function(t)
  {
    var p = t.split(':'), s = 0, m = 1;
    while (p.length > 0) {
      s += m * parseInt(p.pop(), 10);
      m *= 60;
    }
    return s;
  },
  
  dateSplit: function(dstr){
    var d = dstr.toString().split(" - ");
    return {
      fr_d: jQuery.trim(d[0]),
      to_d: jQuery.trim(d[1])
    };
  },
  
  getSelectValues: function(ob_n)
  {
    var vals = [];
    $(ob_n + " :selected").each(function(i, ob){
      vals.push($(ob).attr("value"));
    });
    return vals;
  },
  
  n_kls: function(t)
  {
    // return class name
    return "." + t;  
  },
  
  n_id: function(t)
  {
    // return id name
    return "#" + t;
  },
  
  /* settings */
  cof: {},
  
  /* string and number format */
  fmt: {},
  
  /* dialogs */
  dialog: {},
  
  /* notifications */
  noty: {},
  
  /* validation */
  valid: {},
  
  /* for maintenance */ 
  mnt: {},
  
  /* input autocomplete, select */
  autocomplete: {},
  
  /* evaluation */
  evaluation: {},
  
  /* dataTable */
  dtTable: {},
  
  /* picker */
  picker: {},
  
  /* cookies */
  cookies: {
    set: function(key,val){
      Cookies.set(key, val);
    },
    get: function(key){
      var val = Cookies.get(key);
      if(val === undefined){
        return null;
      } else {
        return val;
      }
    },
    remove: function(key){
      Cookies.remove(key); 
    }
  },
  
  hasCookies: function(){
    try {
    if(navigator.cookieEnabled){
      return true;
    }} catch(e){}
    return false;
  },
  
  // init all
  init: function(){
    function checkPasswordExpiryDialog(){
      var o = $("#password-expiry-dialog");
      if(gon.params.controller !== "users" && o.length > 0 && o.attr("data-expired-flag") == "true"){
        o.removeClass('hide-block');
        var htm = appl.getHtmlTemplate("#template_password_expiry_dialog");
        $("div.block-inner",o).append(htm());
        $("iframe",o).load(function(){
          var flg = $("input#password_expiry_flag",$(this).contents()).val();
          if(flg == "false"){
            o.addClass('hide-block');
          }
        });
      }
    }
    
    function bindLink(){
      $(".mn-link, .btnlink").on("click",function(){
        var url = $(this).attr("data-url");
        if (isPresent(url)) {
          appl.redirectTo(url);
        }
      });
      $("#btn-reports").hover(function(){
        $(".menu-for-reports").stop().show(200);
      },function(){
        $(".menu-for-reports").stop().hide(100);
      });
      $("#btn-more-fnc").hover(function(){
        $("#panel-hidden-menus").stop().show(200);
      },function(){
        $("#panel-hidden-menus").stop().hide(100);
      });
      $("button.btn-help-dialog").off('click').on('click',function(){
        appl.dialog.openHelp($(this).attr("data-man-id"));  
      });
    }
    function setInputMaskField(){
      var fmPh = {
        'pattern': '{{999999999999999}}',
        'persistent': true
      };
      $("input.mask-phonenumber").formatter(fmPh);
      $(".mask-extension").formatter({
        'pattern': '{{99999}}',
        'persistent': true
      });
      $("input.mask-duration").formatter({
        'pattern': '{{9999}}',
        'persistent': true
      }).on('blur',function(){
        var o = $(this);
        var v = jQuery.trim(o.val());
        if (v.length >= 4){
        o.val(v.substr(0,v.length - 2) + ":" + v.substr(-2));
        } else if(v.length > 0) {
        o.val(v + ":" + "00");
        }
      }).on('click',function(){
      var o = $(this);
      var v = jQuery.trim(o.val());
      if (v.length >= 4) {
        if (v.substr(-3) == ":00") {
          v = v.substr(0,v.length - 2);
        }
        v = v.replace(":","");
      }
      if (v.length > 0) {
        o.val(v);
      }
      });
    }
    
    function showFlashMessage(){
      var o = $(".flash-message");
      if (o.length != 0) {
        $.bootstrapGrowl(o.attr("flash-msg"),{
          ele: 'body',
          type: 'info',
          offset: {from: 'top', amount: 50}, 
          align: 'center', 
          width: 350,
          delay: 2500,
          allow_dismiss: true, 
          stackup_spacing: 8 
        });
      }  
    }
    
    function createTooltip() {
      var kls = '.show-tooltip';
      var opts = {
        content: {
          attr: 'data-tooltip'  
        },
        position: {
          my: 'top center',
          at: 'bottom center'
        },
        style: {
          classes: 'qtip-tipsy'
        }
      };
      $(kls).qtip(opts);
    }
    logoutTimer().start();
    bindLink();
    setInputMaskField();
    showFlashMessage();
    createTooltip();
    checkPasswordExpiryDialog();
    try {
      _appSiteRedirection.init();
    } catch(e){}
  }
});

jQuery.extend(appl.fmt,{
  
  // number format
  numberFmt: function(n){
    return (parseInt(n)).format();
  },
  
  // float format
  floatFmt: function(f){
    return parseFloat(f);
  },
  
  // added zero after
  zeroPadAfter: function(n,c_max){
    var c = c_max || 0;
    var s = n.toString()+'';
    while(s.length<c) {
      s = s + "0";
    }
    return s;
  },
  
  // convert datetime format string
  secToHMS: function(secs,pat){
    return appl.fmt.msecToHMS(secs * 1000, pat);
  },
  
  msecToHMS: function(msecs,pat){
    var ms = msecs;
    var pattern = pat || "hh:mm:ss",
    arrayPattern = pattern.split(":"),
    clock = [],
    hours = Math.floor ( ms / 3600000 ), // 1 Hour = 36000 Milliseconds
    minuets = Math.floor (( ms % 3600000) / 60000), // 1 Minutes = 60000 Milliseconds
    seconds = Math.floor ((( ms % 360000) % 60000) / 1000) // 1 Second = 1000 Milliseconds
    
    // build the clock result
    function createClock(unit){
      // match the pattern to the corresponding variable
      if (pattern.match(unit)){
        if (unit.match(/h/)){
          addUnitToClock(hours, unit);
        }
        if (unit.match(/m/)) {
          addUnitToClock(minuets, unit);
        }
        if (unit.match(/s/)) {
          addUnitToClock(seconds, unit);
        }
      }
    }
    
    function addUnitToClock(val, unit){
      if ( val < 10 && unit.length === 2) {
        val = "0" + val;
      }
      clock.push(val); // push the values into the clock array
    }
    
    // loop over the pattern building out the clock result
    for ( var i = 0, j = arrayPattern.length; i < j; i ++ ){
      createClock(arrayPattern[i]);
    }
    
    var clock_text = "";

    clock_text = clock.join(":");
    
    return {
      hours : hours,
      minuets : minuets,
      seconds : seconds,
      clock : clock_text
    };
  },
  
  zeroPad: function(num, places){
    var zero = places - num.toString().length + 1;
    return Array(+(zero > 0 && zero)).join("0") + num;
  }
});

jQuery.extend(appl.dialog,{
  
  // waiting or processing dialog
  _swapPsImage: function(){
    var imgs = [];
  },
  showWaiting: function(){
    window.isOnProcessing = true;
    $("#box-processing-all").css("display","block");
  },
  hideWaiting: function(){
    window.isOnProcessing = false;
    $("#box-processing-all").css("display","none");
  },
  
  // delete cofirmation
  deleteConfirm: function(url){
    bootbox.confirm("Are you sure to delete this?",function(rs){
      if (rs==true) {
        jQuery.post(url,{ _method: 'delete' },function(result){
          window.setTimeout('location.reload()', 5);
          //if (result.result=="deleted") {
          //  window.setTimeout('location.reload()',10);
          //} else {
          //  bootbox.alert(result);
          //}
        });
      }
    });
  },
  
  // delete confirmation (func)
  deleteConfirm2: function(fn_del){
    bootbox.confirm("Are you sure to delete this?",function(rs){
      if (rs===true) {
        fn_del();
      }
    });
  },
  
  // undo delete confirmation
  undeleteConfirm: function(url){
    bootbox.confirm("Are you sure to undelete this?",function(rs){
      if (rs === true) {
        // remote-delete
        jQuery.post(url,function(result){
          if (result=="undeleted") {
            window.setTimeout('location.reload()',10);
          } else {
            bootbox.alert(result);
          }
        });
      }
    });
  },
  
  helpDialog: function(code){
    var url = appl.mkUrl(Routes.manual_index_path(),{ tc: code });
    var hbox = bootbox.dialog({
      title: 'Help',
      message: "<iframe class=\"frame-help\" src=\"" + url + "\"></iframe>",
      animate: false,
      size: 'large'
    });
    hbox.init(function(){
      $("iframe",this).height($(window).height()/2);
    });
  },
  
  openHelp: function(id){
    $("#block-manual-side").show(5,function(){
      $("iframe",this).attr("src",Routes.manual_index_path({ tc: id })).height($(this).height());
      $("#btn-close-manual-dialog").off('click').on('click',function(){
        $("#block-manual-side").hide(5,function(){
          $("iframe",this).removeAttr("src");  
        });
      });
    });
  }
});

jQuery.extend(appl.noty,{
  error: function(s){
    var n = noty({
      layout: 'topCenter',
      text: s,
      type: 'error',
      timeout: 3000,
      theme: 'relax'
    });
  },
  success: function(s){
    var n = noty({
      layout: 'topCenter',
      text: s,
      type: 'success',
      timeout: 3000,
      theme: 'relax'
    });
  },
  info: function(s){
    var n = noty({
      layout: 'topCenter',
      text: s,
      type: 'information',
      timeout: 3000,
      theme: 'relax'
    });
  }
});

jQuery.extend(appl.picker,{
  dateRange: function(obn){
    var fnDefault = function(){
      var o = $(obn);
      if (o.val().length <= 0) {
        var sd = moment().startOf('day').format(appl.cof.moment.fmt_d);
        var td = moment().endOf('day').format(appl.cof.moment.fmt_d);
        $(obn).val(sd + " - " + td);      
      }
    }
    var options = {
      format: appl.cof.moment.fmt_d,
      ranges:{
        'Today': [moment().startOf('day'), moment().endOf('day')],
        'Yesterday': [moment().startOf('day').subtract('days', 1), moment().endOf('day').subtract('days', 1)],
        'Last 7 Days': [moment().startOf('day').subtract('days', 6), moment().endOf('day')],
        'Last 30 Days': [moment().startOf('day').subtract('days', 29), moment().endOf('day')],
        'This Month': [moment().startOf('day').startOf('month'), moment().endOf('day').endOf('month')],
        'Last Month': [moment().startOf('day').subtract('month', 1).startOf('month'), moment().endOf('day').subtract('month', 1).endOf('month')]
      },
      startDate: moment().startOf('day'),
      endDate: moment().endOf('day'),
      timePicker: false,
      minDate: moment().startOf('day').subtract('month',12),
      maxDate: moment().endOf('day'),
      timePicker12Hour: false
    }
    $(obn).daterangepicker(options,function(){});
    $(obn).on('blur',fnDefault);
    fnDefault();
  }
});

jQuery.extend(appl.autocomplete,{
  groupsSelect: function(ob_n,opts){
    var op = opts || {};
    var x_width = '100%';
    if (isPresent(op.width)) {
      x_width = op.width;
    }
    $(ob_n).select2({
      width: x_width,
      placeholder: "",
      allowClear: true,
      ajax: {
        url: Routes.list_groups_path(),
        dataType: 'json',
        cache: true,
        data: function(params){
          return { q: params.term };
        },
        processResults: function(data, page) {
          return { results: data };
        }
      }
    });
  },
  usersSelect: function(ob_n){
    $(ob_n).select2({
      width: '100%',
      placeholder: "",
      allowClear: true,
      ajax: {
        url: Routes.list_users_path(),
        dataType: 'json',
        cache: true,
        data: function(params){
          return { q: params.term, u_init: gon.params.u };
        },
        processResults: function(data, page) {
          return { results: data };
        }
      }
    });
  },
  callTagsSelect: function(ob_n){
    $(ob_n).select2({
      tags: true,
      placeholder: "",
      allowClear: true,
      tokenSeparators: [','],
      width: '100%',
      matcher: function(d){
        console.log(d);  
      },
      data: [{id: 1, text: 'test'}],
      ajax: {
        url: Routes.list_tags_path(),
        dataType: 'json',
        cache: true,
        data: function(params){
          return { q: params.term }
        },
        processResults: function(data, page) {
          return { results: data }
        }
      }
    });
  },
  keywordSelect: function(ob_n){
    $(ob_n).select2({
      tags: false,
      placeholder: "",
      allowClear: true,
      width: '100%',
      ajax: {
        url: Routes.list_keywords_path(),
        dataType: 'json',
        cache: true,
        data: function(params){
          return { q: params.term }
        },
        processResults: function(data, page) {
          return { results: data }
        }
      }
    });
  },
  mailerSelect: function(ob_n){
    $(ob_n).select2({
      tags: true,
      placeholder: "",
      allowClear: true,
      tokenSeparators: [','],
      width: '100%',
      ajax: {
        url: Routes.mailer_users_path(),
        dataType: 'json',
        cache: true,
        data: function(params){
          return { q: params.term }
        },
        processResults: function(data, page) {
          return { results: data }
        }
      }
    });
  }
});

jQuery.extend(appl.evaluation,{
  _DECIMAL_PLACE: 1,
  parseScoreValue: function(v){
    /* parse score value from any to float */
    return (parseFloat(v)).floor(appl.evaluation._DECIMAL_PLACE);
  },
  scoreFormat: function(v){
    /* display in formatted 0.0 */
    return (appl.evaluation.parseScoreValue(v)).format(appl.evaluation._DECIMAL_PLACE);
  },
  scoreVal: function(v,d){
    return (parseFloat(v)).round(appl.evaluation.decimalPlace(6));
  },
  scoreFmtPct: function(v,d){
    return appl.evaluation.scoreFormat(v,d) + "%";
  }
});

jQuery.extend(appl.cof,cof);

/* jQuery extended */
jQuery.fn.clearForm = function() {
  return this.each(function() {
    var type = this.type, tag = this.tagName.toLowerCase();
    var t = this;
    if (tag == 'form')
      return $(':input',t).clearForm();
    if (type == 'text' || type == 'password' || tag == 'textarea'){
      $(t).val('');
    } else if (type == 'checkbox' || type == 'radio'){
      $(t).prop("checked",false);
    } else if (tag == 'select'){
      $(t).prop("selectedIndex",-1);
    }
  });
};

function isNumeric(v){
  return (!isNaN(parseFloat(v)) && isFinite(v));
}

function isNumericRange(v,min,max) {
  function isBetween(v,min,max) {
    if (isNumeric(min) && (v < min)) {
      return false;
    } else if (isNumeric(max) && (v > max)) {
      return false;
    }
    return true;
  }
  return isNumeric(v) && isBetween(parseFloat(v),min,max); 
}

function isFoundElement(obj){
  return ((obj !== null) && (obj.length > 0));
}

function isPresent(obj){
  return (obj !== undefined);
}

function isDefined(obj){
  return isPresent(obj);
}

function isNull(obj){
  return (isPresent(obj) && (obj === null));  
}

function isNotNull(obj){
  return !isNull(obj);  
}

function isEmpty(s){
  return ((s != null) && s.isBlank());
}

function isBlank(s){
  return ((s == null || s.toString().isBlank()));
}

function isSet(s){
  // isPresent + isBlank
  return (isPresent(s) && !isBlank(s));
}

function isNotBlank(s){
  return !isBlank(s);  
}

function isAryEmpty(a){
  return (a.length <= 0)
}

function getVal(objVal){
  if (isPresent(objVal) && isNotNull(objVal)) {
    return jQuery.trim(objVal.toString()).replace(/\'/g,"");
  }
  return "";
}

function splitDateRange(s){
  var a = s.split(" - ");
  return { fromDate: a[0], toDate: a[1] }
}

function isDateTime(d){
  return moment(d).isValid();
}

function isDateTimeFrTo(d1,d2){
  return !(moment(d1).isAfter(d2));
}

function isDateTimeFT(t) {
  if(t.match(/(\d{4}-\d{2}-\d{2} \d{2}:\d{2})( - )(\d{4}-\d{2}-\d{2} \d{2}:\d{2})/i)){
    return true;
  }
  return false;
}

function isDurationFormat(t){
  return true;
}

function isTimeString(t){
  if((t != undefined) && (t != null) && t.match(/(\d{2}:\d{2})/)){
    return true;
  }
  return false;
}

function isDurationFrTo(){
  return true;  
}

function isFoundElement(ele){
  return ((ele !== undefined) && (ele !== null) && (ele.length > 0));
}

function isLengthBetween(t,mi,mx){
  var l = t.length;
  if (l >= mi && l <= mx) {
    return true;
  }
  return false;
}

function onPageReady(){ appl.init(); }
jQuery(document).on('ready page:load',onPageReady);