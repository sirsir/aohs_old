Sugar.extend({
  namespaces: [Array, Date, String, Number, Object]
});

var DEBUG = false;
var USER = "AohsAdmin";
const MAX_MESSAGES = 10000;
// const MAX_MESSAGES = 10;
const NO_SCROLL_BACK = true;
const SUBMIT_AFTER_ADD_DIV = true;

// const DELAY_BETWEEN_MESSAGE = 500
const DELAY_BETWEEN_MESSAGE = 1


// const timeTester = {
//   logs: [],

//   push: function(){
//     timeTester.logs.push(Sugar.Date.format(new Date(), '%F %T.{ms}'))
//   },

//   clear: function(){
//     timeTester.logs = []
//   },

//   print: function(){
//     //alert(timeTester.logs.join("=>"))
//     alert(timeTester.logs.last())
//   }

// }


function externalFx_addNewNotification(para){
  try{
    // timeTester.clear( )
    // timeTester.push( )

    setTimeout(function(){
      watchercliFn.addNewNotification(para)
    }, DELAY_BETWEEN_MESSAGE);
    
  }
  catch(err) {
    log(err.message);
  }
    
}

function externalFx_afterResizeWinForm(){
  try{
    setTimeout(function(){
      watchercliFn.set_items_height()
    }, 1);
    
  }
  catch(err) {
    //log(err.message);
  }
  
}

function externalFx_setTheme_Fontsize(para){
  try{
    setTimeout(function(){
      var paraSplit = para.split(" ")
  
      var theme = paraSplit[0];
      var fontsizeClass = paraSplit[1];
      
      watchercliFn.set_theme(theme)
      watchercliFn.set_fontsize(fontsizeClass)
    }, 1);
    
  }
  catch(err) {
    //log(err.message);
  }
    
}

function externalFx_getJson(url){
  try{
    setTimeout(function(){
      var returnJson = {}

      // Assign handlers immediately after making the request,
      // and remember the jqxhr object for this request

      $.ajaxSetup({
        async: false
      });

      returnJson = ""

     $.getJSON( url, function(data) {
        returnJson = JSON.stringify(data)
      })
      .fail(function() {
        returnJson = ""
      })

      log(returnJson)
      return returnJson
    }, 1);
    
  }
  catch(err) {
    //log(err.message);
  }
}

function externalFx_ShowError(error){
  try{
    setTimeout(function(){
      watchercliFn.showError(error)
    }, 1);
    
  }
  catch(err) {
    //log(err.message);
  }    
}

function externalFx_HideError(error){
  try{
    setTimeout(function(){
      watchercliFn.hideError(error)
    }, 1);    
  }
  catch(err) {
    //log(err.message);
  }    
}

function log(m){
  console.log(m)

  try{
    if (DEBUG){
      var myTextArea = $("#log textarea")
      if (myTextArea.is(':visible')){
        myTextArea.val(myTextArea.val() + '\n' + m);
      }      
    }
    
  }
  catch(err) {
    //log(err.message);
  }
}

var clientAppFn = {
  mousedownOnTitle: false,

  afterSetTheme: function(color){
    try {
      // alert("xxxx")
      bound.afterSetTheme(color);
      // alert(JSON.stringify(color))
      // alert("xxxx")
      // window.external.SaveSetting(theme);
      // bound.afterSetTheme(JSON.stringify(color));
    }
    catch(err) {
      log(err.message);
    }
  },

  SaveSetting: function(theme){
    try {
      bound.saveSetting(theme);
      // window.external.SaveSetting(theme);
    }
    catch(err) {
      log(err.message);
    }
  },

  MouseDown: function(){
    try {
      bound.mousedown()
      // window.external.SaveSetting(theme);
    }
    catch(err) {
      log(err.message);
    }
  },

  MouseUp: function(){
    try {
      bound.mouseup()
      // window.external.SaveSetting(theme);
    }
    catch(err) {
      log(err.message);
    }
  },

  load_Setting: function(){
    try {
      // var settings = window.external.GetSetting()
      var setting = bound.getSetting()

      // alert(JSON.stringify(settings, null, "\t"))
      setting = JSON.parse(setting);

      setting.blinkTaskbar = setting.blinkTaskbar=="True"? true:false;

      setting.opacity = 1 - Number(setting.opacity)

      return setting
      
    }catch(err){
      log(err.message);
      return {
        "blinkTaskbar": true,
        "opacity": 0.8,
      };
    }
  },
  
  UnFlashTaskbar: function(){
    try {
      if (watchercliFn.isAllMessageRead()){
        bound.unFlashTaskbar();
        // window.external.UnFlashTaskbar();
      }
    }
    catch(err) {
      log(err.message);
    }    
  },
  
  FlashTaskbar: function(){
    try {
      bound.flashTaskbar();
      // window.external.FlashTaskbar();
    }
    catch(err) {
      log(err.message);
    }    
  },
  
  SetOpacity: function(intOpac){
    try {
      bound.setOpacity(intOpac)
      // window.external.SetOpacity(intOpac)
    }
    catch(err) {
      log(err.message);
    }
  },
  
  SetThemeMinimized: function(theme){
    try {
      // window.external.SetThemeMinimized( theme )
      bound.setThemeMinimized( theme )
    }
    catch(err) {
      log(err.message);
    }
  },

  SetTaskbarBlinkPara: function(blnBlink, num_unread){
    try {
      bound.setTaskbarBlinkPara( blnBlink, num_unread )
      // window.external.SetTaskbarBlinkPara( blnBlink, num_unread )
    }
    catch(err) {
      log(err.message);
    }
  },

  SetTaskbarHideIfReadAllPara: function(blnHideIfReadAll){
    try {
      bound.setTaskbarHideIfReadAllPara( blnHideIfReadAll )
      // window.external.SetTaskbarHideIfReadAllPara( blnHideIfReadAll )
    }
    catch(err) {
      log(err.message);
    }
  },
  
  ExternalHide: function(){
    try {
      bound.externalHide()
      // window.external.ExternalHide()
    }
    catch(err) {
      log(err.message);
    }
  }  
}

var watchercliFn = {
  assistant: [],
  _template: [
    { id: 'skyblue3' },
    { id: 'black' },
    { id: 'skyblue' },
    { id: 'skyblue2' },
    { id: 'green' },
    { id: 'pink' },
    { id: 'yellow' },
    { id: 'grey' },
    { id: 'classic' }
  ],
  options: {
    isNormalizedfontSize: function(){
      return $("#normalizedfontSize input").attr('checked');
    }
  },
  
  blink: function(selector){
    
    $(selector).stop()
    $(selector).css("opacity",1)
    
    setTimeout(function() {
      $(selector).fadeOut(200, function(){
        $(this).fadeIn(100, function(){
          watchercliFn.blink(this);
        });
      });
    }, 500);    
  },

  blinkNtimes: function(el,N){
    
    var count = 0;
    while (count < N){
      el.fadeOut(200)
      el.fadeIn(200)

      count++;
    }            
  },
  
  unblink: function(selector){
    
    $("*").find(".icon-new i").each(function(){
      var parent = $(this).parent();
      $(this).remove();
      
      var htm = appcli.getHtmlTemplate("#template-message_open", {noEscape: true});
      var str2append = htm();
      parent.append(str2append)
    })
    
  },
  
  blinkAll: function(){
    
    watchercliFn.blink(".icon-new .fa-envelope")
    
  },
  
  unblinkAll: function(){
    
    $("*").find(".icon-new .fa-envelope-open").each(function(){
      var parent = $(this).parent();
      $(this).remove();
      
      var htm = appcli.getHtmlTemplate("#template-message_open", {noEscape: true});
      var str2append = htm();
      parent.append(str2append)
    })
    
  },
  
  setIcon: function(html, mode)
  {
    var str_icon = "fa-comments-o"
    if (mode == "keyword"){
      str_icon = "fa-key"
    }else if (mode == "step"){
      str_icon = "fa-comments-o"
    }else if (mode == "info"){
      str_icon = "fa-info-circle info-color"
    }else if (mode == "warning"){
      str_icon = "fa-warning warning-color"
    }else if (mode == "search"){
      str_icon = "fa-search"
    }
    
    return html.replace(/fa-icon/mig, str_icon)
  },
  
  setCaption: function(html, mode)
  {
    var captionClass = ""
    if (mode == "keyword"){
      
    }else if (mode == "step"){
      
    }else if (mode == "info"){
      
    }else if (mode == "warning"){
      captionClass = "warning-color"
    }
    
    return html.replace(/caption-color/mig, captionClass)
  },
  
  loadsample: function()
  {
    if (! DEBUG){
      log("DEBUG=false !=> loadsample()")
      return;
    }

    watchercliFn.assistant = [
      {
        "topic": "Recommend Talk Script",
        "timestamp": "2017-11-01 10:11:42",
        "body": "<div data-content-type=\"faq\"><div>\n <div class=\"block-left\"><a href=\"http://google.com\">Google</a><a href=\"ng:xxsx\">NG:xxxx</a>Customer said: ตกงานอยู่</div>\n <div class=\"block-right\">\n  <ul><li data-action-url=\"watchercli/log/1711-o5KuQjZVS9A/6?item_id=7read=true\" data-item-type=\"btn\">njiojoij</li><li data-action-url=\"watchercli/log/1711-o5KuQjZVS9A/6?item_id=5read=true\" data-item-type=\"btn\">ควรแนะนำว่า</li></ul>\n </div>\n <div class=\"block-comment\" ><input type\"text\"=\"\" name=\"comment\"><button type=\"button\" data-action-url=\"watchercli/log/1711-o5KuQjZVS9A/6?read=true\" data-item-type=\"btn\">Submit</button></div>\n</div></div>\n",
        "type": "faq"
      },
      {
        "topic": "Warning: พบคำหยาบ",
        "timestamp": "2017-11-01 10:11:42",
        "body": "<div data-content-type='keyword'><div data-action-url=\"watchercli/log/1711-TG95qnCBUjY/95?read=true\" data-item-type=\"btn\"><p>NG: <span style=\"color: rgb(255, 0, 0);\"><b style=\"\"><span style=\"font-size: 18px;\">โกหก</span></b><span style=\"font-size: 18px;\">﻿</span><span style=\"font-size: 18px;\">﻿</span><span style=\"font-size: 18px;\">﻿</span></span></p><p>ห้ามพูด! <span style=\"font-size: 18px; color: rgb(255, 0, 0);\">คำหยาบ</span></p></div></div>",
        "type": "faq"
      },
      {
        "topic": "Recommend Talk Script",
        "timestamp": "2017-11-01 10:11:42",
        "body": "<div data-content-type='keyword'><div><p>Customer: \“ไปทำงานต่างประเทศ\”<br></p></div><ul><li data-action-url=\"\" data-item-type=\"btn\"><p><span style=\"font-size: 13.3333px;\">ในระหว่างลูกค้าไปทำงานต่างประเทศอาจไม่สะดวกเรื่องการชำระ แนะนำให้ลูกค้าทำรายการหักยอดชำระผ่านบัญชี เพื่อให้การชำระเป็นไปอย่างต่อเนื่อง</span><br></p></li><li data-action-url=\"\" data-item-type=\"btn\"><p><span style=\"font-size: 13.3333px;\">คุณลูกค้า ขอโทษน่ะครับไม่ทราบว่าสามารถติดต่อเขาได้ไหมครับ เนื่องจากมีธุระน่ะครับ ฝากโทร และรบกวนประสานงานให้เขาติดต่อกลับได้ไหมครับ</span><br></p></li><li data-action-url=\"\" data-item-type=\"btn\"><p><span style=\"font-size: 13.3333px;\">ไม่ทราบว่าทางลูกค้าอนุญาติให้บริษัทติดต่อใครที่เป็นธุระแทนลูกค้าในระหว่างลูกค้าไปทำงานต่างประเทศในเรื่องการชำระ</span><br></p></li></ul></div>",
        "type": "warning"
      },
      {
        "topic": "NG Word ไม่เข้าใจ",
        "timestamp": "2017-11-01 10:11:42",
        "body": "<div data-content-type='keyword'><div><p>Just now you said ไม่เข้าใจ<br></p></div><ul><li data-action-url=\"\" data-item-type=\"btn\"><p><span style=\"font-size: 13.3333px;\">Recommend Talk Script;</span><br style=\"font-size: 13.3333px;\"><span style=\"font-size: 13.3333px;\">I.คุณพอจะหยิบยืมจากคนรู้จักหรือเพื่อนก่อนได้มั้ยคะ/ครับ</span><br style=\"font-size: 13.3333px;\"><span style=\"font-size: 13.3333px;\">II.คุณจ่ายก่อนภายในวันนี้ 50% ส่วนที่เหลือค่อยจ่ายทีหลัง</span><br></p></li><li data-action-url=\"\" data-item-type=\"btn\"><p><span style=\"font-size: 13.3333px;\">Recommend Talk Script;</span><br style=\"font-size: 13.3333px;\"><span style=\"font-size: 13.3333px;\">I.คุณพอจะหยิบยืมจากคนรู้จักหรือเพื่อนก่อนได้มั้ยคะ/ครับ</span><br style=\"font-size: 13.3333px;\"><span style=\"font-size: 13.3333px;\">II.คุณจ่ายก่อนภายในวันนี้ 50% ส่วนที่เหลือค่อยจ่ายทีหลัง</span><br></p></li><li data-action-url=\"\" data-item-type=\"btn\"><p><span style=\"font-size: 13.3333px;\">Recommend Talk Script;</span><br style=\"font-size: 13.3333px;\"><span style=\"font-size: 13.3333px;\">I.คุณพอจะหยิบยืมจากคนรู้จักหรือเพื่อนก่อนได้มั้ยคะ/ครับ</span><br style=\"font-size: 13.3333px;\"><span style=\"font-size: 13.3333px;\">II.คุณจ่ายก่อนภายในวันนี้ 50% ส่วนที่เหลือค่อยจ่ายทีหลัง</span><br></p></li></ul></div>",
        "type": "warning"
      },
      {
        "topic": "Recommend notification",
        "body": "<ul><li data-action-url=\"watchercli/log/1710-3pc9_bBYxXA/70?read=true\" data-item-type=\"btn\">Recommend Talk Script;<br />\nI.คุณพอจะหยิบยืมจากคนรู้จักหรือเพื่อนก่อนได้มั้ยคะ/ครับ<br />\nII.คุณจ่ายก่อนภายในวันนี้ 50% ส่วนที่เหลือค่อยจ่ายทีหลัง</li><li data-action-url=\"watchercli/log/1710-3pc9_bBYxXA/70?read=true\" data-item-type=\"btn\">Link for more info<br />\n<a>Link</a><br /></li><li data-action-url=\"watchercli/log/1710-3pc9_bBYxXA/70?read=true\" data-item-type=\"btn\">Rate this content<br />\n<select name=\"rate\">\n  <option value=\"1\">Useful.</option>\n  <option value=\"2\">Content Not Correct.</option>\n  <option value=\"3\">Customer Not Satisfied.</option>\n</select><br />\nComment:<br />\n<input type=\"textarea\" /></li></ul>\n",
        "type": "search",
        "timestamp": "2017-08-01 09:44:48"
      },
      {
        "topic": "Conversation starts",
        "body": "<div>Don't Forget to:<br/><input type=\"checkbox\" name=\"animal\" value=\"Cat\" />Do friendly greeting <br /><input type=\"checkbox\" name=\"animal\" value=\"Dog\" />Identify yourself<br /><input type=\"checkbox\" name=\"animal\" value=\"Bird\" />Clarify our company<br /></div><div>Top Script:<div><ul><li>ABCสวัสดีค่ะ %NAME% รับสายยินดีให้บริการค่ะ</li><li>สวัสดีค่ะ ดิฉัน %NAME% จากABCค่ะ</li><li>เพื่อความปลอดภัยของข้อมูลลูกค้าดิฉันขออนุญาตสอบถามข้อมูลเพิ่มเติมขอทราบหมายเลขบัตรประชาชนค่ะ</li><li><a href='#'>...</a></li></ul></div></div>",
        "type": "step",
        "timestamp": "2017-08-01 09:44:48"
      },
      {
        "topic": "You are speaking too fast",
        "body": "Please slow down and speak clearly.",
        "type": "warning",
        "timestamp": "2017-08-01 09:45:03"
      },
      {
        "topic": "Keywords: ลดหย่อนภาษี",
        "type": "keyword",
        "body": "<div>Top Script:<div><ul><li>Top script 1</li><li>Top script 2</li></ul></div></div><div>Products<div><ul><li><a href='aaa'>แบบประกัน A</a></li><li><a href='bbb'>แบบประกัน B</a></li><li><a href='ccc'>แบบประกัน C</a></li></ul></div></div>",
        "timestamp": "2017-08-01 09:45:21"
      },
      {
        "topic": "Keywords: โปรโมชั่น",
        "type": "keyword",
        "body": "<div>Top Script:<div><ul><li>Top script 1</li><li>Top script 2</li></ul></div></div><div>Products<div><ul><li><a href='aaa'>แบบประกัน A</a></li><li><a href='bbb'>แบบประกัน B</a></li><li><a href='ccc'>แบบประกัน C</a></li></ul></div></div>",
        "timestamp": "2017-08-01 09:46:48"
      },
      {
        "topic": "วิธีการชำระเงิน",
        "type": "info",
        "body": "<div>Top Script:<div><ul><li>Top script 1</li><li>Top script 2</li></ul></div></div><div>Payment methods:<div><ul><li><a href='aaa'>payment method A</a></li><li><a href='bbb'>payment method B</a></li><li><a href='ccc'>payment method C</a></li></ul></div></div>",
        "timestamp": "2017-08-01 09:46:48"
      },
      {
        "topic": "วิธีการชำระเงิน",
        "type": "info",
        "body": "<div>Top Script:<div><ul><li>Top script 1</li><li>Top script 2</li></ul></div></div><div>Payment methods:<div><ul><li data-action-url='watchercli/log/1709-5j4iqeIOAnM/57?read=true' data-item-type='btn'><a href='aaa'>payment method A</a></li><li data-item-type='btn'><a href='bbb'>payment method B</a></li><li data-item-type='btn'><a href='ccc'>payment method C</a></li></ul></div></div>",
        "timestamp": "2017-08-01 09:46:48"
      }
    ];
    
    watchercliFn.assistant.reverse();
    
    watchercliFn.assistant.forEach(function(item, idx){
      
      var htm = appcli.getHtmlTemplate("#template-topic", {noEscape: true});
      var title = item.topic
      title = (title!="")? title: "Untitled"
      
      var timestamp = watchercliFn.format_time(item)
      
      var body =  item.body;
      
      var dataContentType = watchercliFn.get_dataContentType(body)
    
      var str2append = htm({title: title, idx: idx, body: body, timestamp: timestamp, dataContentType: dataContentType});

      // var str2append = htm({title: title, idx: idx, timestamp: timestamp, body: body});
      
      str2append = watchercliFn.setIcon(str2append,item.type)
      str2append = watchercliFn.setCaption(str2append,item.type)
      
      $("#wc-topic_list .items").prepend(str2append)
    })

    // $("#wc-topic_list .item .body").hide();
    watchercliFn.blinkNtimes($("#wc-topic_list .item .icon-new i"),5)
    
    watchercliFn.set_AfterAddNotification();
    
  },

  loadsampleSearch: function()
  {
    if (! DEBUG){
      log("DEBUG=false !=> loadsampleSearch()")
      return;
    }

    watchercliFn.assistant = [
      {
        "topic": "Search Result",
        "body": "<ul><li data-action-url=\"watchercli/log/1710-3pc9_bBYxXA/70?read=true\" data-item-type=\"btn\">Recommend Talk Script;<br />\nI.คุณพอจะหยิบยืมจากคนรู้จักหรือเพื่อนก่อนได้มั้ยคะ/ครับ<br />\nII.คุณจ่ายก่อนภายในวันนี้ 50% ส่วนที่เหลือค่อยจ่ายทีหลัง</li><li data-action-url=\"watchercli/log/1710-3pc9_bBYxXA/70?read=true\" data-item-type=\"btn\">Link for more info<br />\n<a>Link</a><br /></li><li data-action-url=\"watchercli/log/1710-3pc9_bBYxXA/70?read=true\" data-item-type=\"btn\">Rate this content<br />\n<select name=\"rate\">\n  <option value=\"1\">Useful.</option>\n  <option value=\"2\">Content Not Correct.</option>\n  <option value=\"3\">Customer Not Satisfied.</option>\n</select><br />\nComment:<br />\n<input type=\"textarea\" /></li></ul>\n",
        "type": "search",
        "timestamp": "2017-08-01 09:44:48"
      }
      
    ];
    
    watchercliFn.assistant.reverse();
    
    watchercliFn.assistant.forEach(function(item, idx){
      
      var htm = appcli.getHtmlTemplate("#template-topic", {noEscape: true});
      var title = item.topic
      title = (title!="")? title: "Untitled"
      
      var timestamp = watchercliFn.format_time(item)
      
      var body =  item.body;
      
      var dataContentType = watchercliFn.get_dataContentType(body)
    
      var str2append = htm({title: title, idx: (watchercliFn.assistant.length-1), body: notification.body, timestamp: timestamp, level: level, dataContentType: dataContentType});

      // var str2append = htm({title: title, idx: idx, timestamp: timestamp, body: body});
      
      str2append = watchercliFn.setIcon(str2append,item.type)
      str2append = watchercliFn.setCaption(str2append,item.type)
      
      $("#wc-topic_list .items").prepend(str2append)
    })

    // $("#wc-topic_list .item .body").hide();
    watchercliFn.blinkNtimes($("#wc-topic_list .item .icon-new i"),5)
    
    watchercliFn.set_AfterAddNotification();
    
  },

  toggleItemSearch: function(searchmode){
    if (searchmode){

      $('div[data-content-type]:not(.search)').closest('.item').show()

      $('.item').each(function(){
        var obj = $(this)

        if (obj.find('.search').length === 0){
          obj.hide()
        }
      })
    }else{
      // $('div[data-content-type].search').closest('.item').remove()

      $('div[data-content-type]:not(.search)').closest('.item').hide()

      $('.item').each(function(){
        var obj = $(this)

        if (obj.find('.search').length === 0){
          obj.show()
        }
      })
    }
  },
  
  set_SearchClickEvent: function(){
    $("#search").hide();

    $("#search-button").off("click").on("click", function(){
      
      if ($("#search").is(":visible")){
        $("#search").hide();

        watchercliFn.toggleItemSearch(false)
      }else{
        $("#search").show();
        $("#setting").hide();

        watchercliFn.toggleItemSearch(true)
      }      
      
    })

    watchercliFn.set_items_height();
    
  },

  set_SettingClickEvent: function(){
    
    $("#setting-button").off("click").on("click", function(e){

      if (e.shiftKey){

        DEBUG = true

        $("#wc-topic_list .title-row .delete").toggle()

      }else if(e.altKey){

        DEBUG = true;

        $("#log").toggle()

      }else{
        var clickedObj = $(this);
      
        if ($("#setting").css("display") != "none"){
          
          var theme = $("#wc-notification").attr("class");
          
          clientAppFn.SaveSetting(theme)


        }else{
          var setting = clientAppFn.load_Setting();

          $("#sliderOpacity").val(setting.opacity);
          $("#blinkTaskbar input").attr('checked', setting.blinkTaskbar);

          $("#search").hide();
          watchercliFn.toggleItemSearch(false)
          
        }
        
        $("#setting").toggle();
      }
      
    })

    watchercliFn.set_items_height();
    
  },

  set_SettingElementsEvent: function(){
    $("#sliderOpacity").off("mouseup").on("mouseup", function(){
      var clickedObj = $(this);
      var obj2change = $("#wc-notification")
      
      clientAppFn.SetOpacity(clickedObj.val())
      
    })

    $("#blinkTaskbar input").change(function(){
      var clickedObj = $(this);
      var num_unread = $(".wc-messages .item[data-alreadyRead=false]").length

      clientAppFn.SetTaskbarBlinkPara(clickedObj.is(':checked'), num_unread)
      
    })

    $("#normalizedfontSize input").change(function(){
      var clickedObj = $(this);

      if (clickedObj.is(':checked')){
        $(".items").addClass('normalized-fontsize')
      }else{
        $(".items").removeClass('normalized-fontsize')
      }
      
    })

    

    $("#hideTaskbar input").change(function(){
      var clickedObj = $(this);
      
      clientAppFn.SetTaskbarHideIfReadAllPara(clickedObj.is(':checked'))
      
    })
    
  },

  set_BodyContent_ClickEvent: function(){
    $(".body-content").off("click").on("click", function(){
      var clickedObj = $(this);

      var is_delete_case = false

      var parentObj = clickedObj.closest(".item");

      if (parentObj.attr('data-content-type') == 'search'){
        return;
      }

      if ( (clickedObj.find("li[data-item-type='btn']").length == 0) &&
        (clickedObj.find("div[data-action-url]").length == 0))
      {
          is_delete_case = true
      }

      if (is_delete_case){

        watchercliFn.removeWithEffect(parentObj);
      }      
    })
  },

  removeWithEffect: function(jqObj){
    jqObj.fadeOut("slow",function(){
      
      jqObj.remove();

      watchercliFn.SetFlashing();      
      
      watchercliFn.update_total_messages();
      
    });        
  },
  
  set_Button_ClickEvent: function(){
    $("button[data-action-url]").closest('div').find('input').off().keyup(function(e){
        if(e.keyCode == 13)
        {
            $(this).closest('div').find('button').trigger('click')
            return false;
        }
    });

    $("button[data-action-url]").off("click").on("click", function(){
      var clickedObj = $(this);
      var input = clickedObj.closest("div").find('input')
      var parentObj = clickedObj.closest(".item");  
      
      var url = clickedObj.attr("data-action-url")

      var content = input.val()

      url = url+"&comment="+content

      // log(url)
      
      url = Routes.home_index_path().replace("home","") + url;

      var parent0 = clickedObj.closest('div')
      parent0.find('.error,.success').remove()

      if (content.length < 2){
        parent0.append('<div class="error">Please input data.</div>')
        return;
      }

      $.ajax({
        method: "GET",
        url: url,
        dataType: 'html',
        success: function( data ) {
          // alert( "SUCCESS:  " + data );
          log(data)

          if (data=="ok"){

            log(data)
            
            parent0.append('<div class="success">Data is submitted succesfully:)</div>')

            setTimeout(function(){
              watchercliFn.removeWithEffect(parentObj);

              watchercliFn.SetFlashing();
            }, 1000)
            
          }else{
            log(data)
            
            parent0.append('<div class="error">Error! Can\'t submit data. Please try again.</div>')
          }
        },
        error: function( data ) {
          log(data)
          parent0.append('<div class="error">Error! Can\'t submit data. Please try again.</div>')          
        }
      });          
    })
  },

  set_DataItemType_ClickEvent: function(){
    $("div[data-item-type='btn'],li[data-item-type='btn']").off("click").on("click", function(){
      var clickedObj = $(this);
      
      var url = clickedObj.attr("data-action-url")
      
      url = Routes.home_index_path().replace("home","") + url;
      $.getJSON(url, function(data, status){
        //alert("Data: " + data + "\nStatus: " + status);
      });

      var parentObj = clickedObj.closest(".item");

      if (parentObj.attr('data-content-type') == 'search'){
        return;
      }      

      watchercliFn.removeWithEffect(parentObj);

      watchercliFn.SetFlashing();
      
    })
  },

  set_KeywordType_ClickEvent: function(){
    // $("div[data-content-type='keyword'] div[data-action-url]").off("click").on("click", function(){
    //   var clickedObj = $(this);
      
    //   var url = clickedObj.attr("data-action-url")
      
    //   url = Routes.home_index_path().replace("home","") + url;
    //   $.getJSON(url, function(data, status){
    //     //alert("Data: " + data + "\nStatus: " + status);
    //   });

    //   var parentObj = clickedObj.closest(".item");      

    //   watchercliFn.removeWithEffect(parentObj);

    //   watchercliFn.SetFlashing();
      
    // })
  },
  
  setTopicClickEvent: function(){
    $("#wc-topic_list .item .head").off("click").on("click", function(){
      
      var clickedObj = $(this).closest(".item");

      clickedObj.attr("data-alreadyRead","true");


      clickedObj.find(".delete").css('visibility','visible')
      
      $("#wc-topic_list .item").removeClass( "item_clicked" );
      clickedObj.addClass( "item_clicked" );
      
      var current_display = clickedObj.children( ".body" ).css( "display" );
      
      // $("#wc-topic_list .item .body").css( "display", "none" );
      $("#wc-topic_list .item .expand i").addClass( "fa-chevron-down" );
      
      if (current_display == "none"){
        clickedObj.children( ".body" ).css( "display", "table" );
        clickedObj.find(".expand i").removeClass( "fa-chevron-down" );
        clickedObj.find(".expand i").addClass( "fa-chevron-up" );
        
        clickedObj.find(".icon-new i").removeClass( "fa-envelope" );
        clickedObj.find(".icon-new i").addClass( "fa-envelope-open" );
        
        clientAppFn.UnFlashTaskbar();
        
      }else{
        
        clickedObj.children( ".body" ).css( "display", "none" );
        clickedObj.find(".expand i").removeClass( "fa-chevron-up" );
        clickedObj.find(".expand i").addClass( "fa-chevron-down" );
      }
      
      // watchercliFn.unblinkAll()
      // watchercliFn.blinkAll()
      
    })
    
    $("#wc-topic_list .item .delete").off("click").on("click", function(){
      
      var clickedObj = $(this).closest(".item");
      
      // clickedObj.remove();
      watchercliFn.removeWithEffect(clickedObj);

      watchercliFn.SetFlashing();
      
    })
    
  },
  
  set_ThemeChangeRadio: function(){
    
    var htm = appcli.getHtmlTemplate("#template-color-buttons", {noEscape: true});
    var str2append = htm(watchercliFn._template);
    
    $('#setting #select-theme').empty().append(str2append);
    
    $('#setting #select-theme a').on('click', function(e) {
      
      var clickedObj = $(this);
      var obj2change = $("#wc-notification")

      var theme = clickedObj.attr("id")
      
      clickedObj.siblings().each(function(){
        $(this).removeClass("checked")
        $(this).find("i").removeClass("fa-check").addClass("fa-font")
        
        var theme_i = $(this).attr("id")
        log(theme_i)
        obj2change.removeClass("theme-"+theme_i)
        
      })
      
      clickedObj.find("i").addClass("fa-check").removeClass("fa-font")
      clickedObj.addClass("checked");
      
      obj2change.addClass("theme-"+theme)
      
      clientAppFn.SetThemeMinimized( theme )

      watchercliFn.afterSetTheme()
            
    });
    
  },

  afterSetTheme:function(){
    setTimeout(function(){
      var color = $("#wc-notification").css('background-color')
      // alert(color)
      clientAppFn.afterSetTheme(color)
    },200)
  },

  set_theme:function(theme){
    
    var obj2change = $("#wc-notification")
    var buttons = $("#select-theme a")
    
    obj2change.removeClass(function (index, className) {
      return (className.match(/(^|\s)theme-\S+/g) || []).join(' ');
    });
    
    $("i", buttons).removeClass("fa-check").addClass("fa-font");
    $("a[data-theme-name=\"" + theme + "\"] i").removeClass("fa-font").addClass("fa-check");
    
    obj2change.addClass("theme-" + theme)

    watchercliFn.afterSetTheme()

  },
  
  set_fontsize:function(fontsizeClass){
    
    var obj2change = $("#wc-notification")
    var buttons = $("#select-theme a")
    
    obj2change.removeClass(function (index, className) {
      return (className.match(/(^|\s)wc-font-\S+/g) || []).join(' ');
    });
    
    obj2change.addClass("wc-font-" + fontsizeClass)
  },
  
  set_ClearAll: function(){
    
    $("#wc-topic_list .title-row .delete").off("click").on("click", function(e){
      
      if (e.shiftKey){
        watchercliFn.loadsample();
      }else{
        var assitantDetailObj = $("#wc-assistant .detail");
        assitantDetailObj.empty();

        watchercliFn.removeWithEffect($("#wc-topic_list .item"));

        watchercliFn.SetFlashing();
      }
      
    })
  },
  
  set_Minimize: function(){
    
    $("#minimize-button").off("click").on("click", function(){
      
      $("#minimize-button").off("click").on("click", function(e){

        if (e.shiftKey){
          DEBUG = false;

          watchercliFn.set_VisibleHide4all()
        }else if (e.altKey){
           location.reload();
        }else{
          clientAppFn.ExternalHide()

          $("#minimize-button").hide()
          $("#maximize-button").show()
        }

      })      
      
    })

    $("#maximize-button").off("click").on("click", function(){
      
      clientAppFn.ExternalHide()

      $("#minimize-button").show()
      $("#maximize-button").hide()
      
    })
  },

  set_DragFeature: function(){
    
    $("#wc-notification .title-row > div:first").off("mousedown").on("mousedown", function (e) {

      clientAppFn.mousedownOnTitle = true;

      setTimeout(function () {
          if(clientAppFn.mousedownOnTitle) {
              clientAppFn.MouseDown()
          }
      }, 100);

    })

    $("#wc-notification .title-row > div:first").off("mouseout").on("mouseout", function () {
      clientAppFn.mousedownOnTitle = false;
      clientAppFn.MouseUp()      
    })
  },
  
  set_PageFontResizer: function(){
    
    $("#setting .increase-size").off("click").on("click", function(e){
      
      var obj2change = $("#wc-notification");
      
      e.stopPropagation();
      
      obj2change.removeClass(function (index, className) {
        return (className.match(/(^|\s)wc-font\S+/g) || []).join(' ');
      });
      
      obj2change.addClass("wc-font-bigger")
      
    })
    
    $("#setting .decrease-size").off("click").on("click", function(e){
      
      var obj2change = $("#wc-notification");
      
      e.stopPropagation();
      
      obj2change.removeClass(function (index, className) {
        return (className.match(/(^|\s)wc-font\S+/g) || []).join(' ');
      });
      
      obj2change.addClass("wc-font-normal")
      
    })
    
    $("#setting .default-size").off("click").on("click", function(e){
      
      var obj2change = $("#wc-notification");
      
      e.stopPropagation();
      
      obj2change.removeClass(function (index, className) {
        return (className.match(/(^|\s)wc-font\S+/g) || []).join(' ');
      });
      
      obj2change.addClass("wc-font-big")
      
    })
  },
  
  set_FontResizer: function(){
    
    $(".item .increase-size").off("click").on("click", function(e){
      
      e.stopPropagation();
      
      var clickedObj = $(this)
      var obj2resize = clickedObj.closest('.body').children(".body-content")
      
      ZoomFont.in(obj2resize);
      
    })
    
    $(".item .decrease-size").off("click").on("click", function(e){
      
      e.stopPropagation();
      
      var clickedObj = $(this)
      var obj2resize = clickedObj.closest('.body').children(".body-content")
      
      ZoomFont.out(obj2resize);
      
    })
    
    $(".item .default-size").off("click").on("click", function(e){
      
      e.stopPropagation();
      
      var clickedObj = $(this)
      var obj2resize = clickedObj.closest('.body').children(".body-content")
      
      ZoomFont.reset(obj2resize);
      
    })
  },
  
  format_time: function(objIn){
    var timeStr = objIn.timestamp

    if (!timeStr){
      return ""
    }

    //with second
    // return timeStr.split(" ").last()

    // without second
    // return timeStr.split(" ").last().replace(/^(.*):.*$/,"$1")

    //with second AmPm
    timeArray = timeStr.split(" ").last().split(":")

    hr = Number(timeArray[0])

    timeStrAmPm = ( hr > 12 )? " PM" : " AM";

    timeArray[0] = ( hr > 12 )? Sugar.Number.pad(hr-12, 2) : timeArray[0];



    return timeArray.join(":") + timeStrAmPm
  },
  
  get_level: function(notification){
    try {
      level = "";
      
      if (notification.hasOwnProperty("level")){
        level=notification.level;
      }else if (notification.hasOwnProperty("body")){
        
        if (notification.body.toLowerCase().includes("#4f94cd")){
          level = "info";
        }else if(notification.body.toLowerCase().includes("#ff8c00") ) {
          level = "warning";
        }else if (notification.body.toLowerCase().includes("info")){
          level = "info";
        }else if(notification.body.toLowerCase().includes("warn") ) {
          level = "warning";
        }
      }
      
      return level;
    }
    catch(err) {
      return "";
    }
    
  },
  
  get_body: function(notification){
    
    try {
      if (! notification){
        return "";
      }
      
      body = "";
      
      if (notification.hasOwnProperty("body")){
        
        if (notification.body){
          body=notification.body;
          var bodyhack = body.match(/<bodyhack.*?>(.*)<\/bodyhack>/i)
          if (bodyhack){
            body = bodyhack[1]
          }
        }
        
      }
      return body;
    }
    catch(err) {
      return "";
    }
    
  },
  
  get_title: function(notification){
    
    try {
      if (! notification){
        return "";
      }
      
      var title = "";
      
      if (notification.hasOwnProperty("title") || notification.hasOwnProperty("topic")){
        title=notification.title || notification.topic;
      }
      
      if (title == "" && notification.hasOwnProperty("body")){
        
        if (notification.body){
          var hack = notification.body.match(/<!-- (.*?) -->/i)
          
          if (hack){
            title = hack[1]
            title = jQuery('<div />').html(title).text()
          }
        }
        
      }
      return title;
    }
    catch(err) {
      return "";
    }
    
  },
  
  addNewNotification_formatTitle: function(title){
    newTitle = (title!="")? title: "Untitled: (" + (watchercliFn.assistant.length-1) + ")"

    // var MaxCharacter = 20
    // newTitle = (newTitle.length < MaxCharacter)? title: title.substring(0, MaxCharacter-3) + "...";

    return newTitle
  },

  deleteOldNotification: function(notificationIn){
    // var number_of_notification = $(".item").length
    // for (var i=number_of_notification-1;i>MAX_MESSAGES-1;i--){
    //   // $(".item")[i].remove();
    // }

    $(".item").each(function( index ) {
      if (index > MAX_MESSAGES-2){
        $(this).remove();
      }
    });
  },

  addNewNotification: function(notificationIn){
    //~ For debug
    // log(typeof notificationIn)
    // alert(JSON.stringify(notificationIn,null,"\t"))
    // log(JSON.stringify(notificationIn,null,"\t"))

    // timeTester.push( )

    if (Array.isArray(notificationIn)){
      notificationIn.forEach(function(n){
        setTimeout(function(){
          watchercliFn.addNewNotification(n)
        }, DELAY_BETWEEN_MESSAGE)
      })
      return;
    }

    // timeTester.push( )

    watchercliFn.deleteOldNotification();
    
    var notification = ""

    //~ Uncomment client send para as string
    if (typeof notificationIn === 'string' || notificationIn instanceof String){
      notification = JSON.parse(notificationIn);
    }else{
      notification = notificationIn
    }

    // alert(JSON.stringify(notification))

    notification.body = notification.content_details
    
    var notificationFormatted = {};
    
    notificationFormatted.topic = notification.title
    notificationFormatted.body = notification.body
    
    watchercliFn.assistant.push(notificationFormatted);
    
    var htm = appcli.getHtmlTemplate("#template-topic", {noEscape: true});
    
    var title = watchercliFn.get_title(notification)
    title = watchercliFn.addNewNotification_formatTitle(title)
    
    var body = watchercliFn.get_body(notification)

    var dataContentType = watchercliFn.get_dataContentType(body)
    
    var timestamp = watchercliFn.format_time(notification)
    
    var level = watchercliFn.get_level(notification)
    
    var str2append = htm({title: title, idx: (watchercliFn.assistant.length-1), body: body, timestamp: timestamp, level: level, dataContentType: dataContentType});

    str2append = watchercliFn.setIcon(str2append,level)
    str2append = watchercliFn.setCaption(str2append,level)

    watchercliFn.addDiv($("#wc-topic_list .items"),str2append, NO_SCROLL_BACK);
    
    // timeTester.push( )
    // timeTester.print()

    watchercliFn.set_AfterAddNotification();    
    
  },

  get_dataContentType: function(body){
    
    try{
      // var strReturn = ''
      log(body)

      var regexp = /data-content-type= ?["'](.*?)["']/i;
      var matches_array = body.match(regexp);

      log(matches_array)

      if (! matches_array){
        return ''
      }
      
      return matches_array[1]

    }catch(err) {

      return ''
    }    

  },

  addNewNotification_SearchResult: function(notification){
    //~ For debug
    //alert(JSON.stringify(notification,null,"\t"))
    
    // var notification = ""
    // notification.body = notification.content_details
    
    var notificationFormatted = {};
    
    notificationFormatted.topic = notification.topic
    notificationFormatted.body = notification.body
    
    watchercliFn.assistant.push(notificationFormatted);
    
    var htm = appcli.getHtmlTemplate("#template-topic", {noEscape: true});
    
    var title = watchercliFn.get_title(notification)
    title = watchercliFn.addNewNotification_formatTitle(title)
    
    var timestamp = watchercliFn.format_time(notification)

    var level = "search"

    // var dataContentType = watchercliFn.get_dataContentType(notification.body)
    var dataContentType = "search"
    
    var str2append = htm({title: title, idx: (watchercliFn.assistant.length-1), body: notification.body, timestamp: timestamp, level: level, dataContentType: dataContentType});


    str2append = watchercliFn.setIcon(str2append,level)
    str2append = watchercliFn.setCaption(str2append,level)

    watchercliFn.addDiv($("#wc-topic_list .items"),str2append, true);
    
    watchercliFn.set_AfterAddNotification();    
    
  },

  update_total_messages: function(){
    if (DEBUG){
      $(".total-messages").show()

      $(".total-messages").html("{0} of {1}".format($(".item[data-content-type='faq']").length, $(".items .item").length))
    }
  },

  addDiv: function(mainDiv, subDiv, noScrollBack){
    var lastScrollTop = mainDiv.scrollTop();
    
    mainDiv.prepend(subDiv)

    if (mainDiv.find(".item").length > 0 ){
      var newScrollTop = lastScrollTop + mainDiv.find(".item").first().outerHeight();
      if (noScrollBack){
        mainDiv.scrollTop(0);
      }else{
        mainDiv.scrollTop(newScrollTop);
      }
      log(noScrollBack)
      
    }

    if (SUBMIT_AFTER_ADD_DIV){
      // alert($( subDiv).find('*[data-action-url]'))
      // alert( $($(subDiv).find('*[data-action-url]').first()).attr('data-action-url') )
      // $($.find('*[data-action-url]').first()).attr('data-action-url')
      //yyyy-MM-dd hh:mm:ss
      var url = $($(subDiv).find('*[data-action-url]').first()).attr('data-action-url')

      var queryParameters = {},
      re = /([^?&=]+)=([^&]*)/g, m;
      while (m = re.exec(url)) {
          queryParameters[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
      }

      url = url.replace(/\?.*$/,'?popup=yes&dsp_at='+Sugar.Date.format(new Date(), '%F %T.{ms}'))

      if (queryParameters.ts){
        url = url + "&ts=" + queryParameters.ts;
      }

      url = Routes.home_index_path().replace("home","") + url;

      $.ajax({
        method: "GET",
        url: url,
        dataType: 'html',
        success: function( data ) {
          // alert( "SUCCESS:  " + data );
          log(data)

          if (data=="ok"){

            log(data)
            
            parent0.append('<div class="success">Data is submitted succesfully:)</div>')

            setTimeout(function(){
              watchercliFn.removeWithEffect(parentObj);

              watchercliFn.SetFlashing();
            }, 1000)
            
          }else{
            log(data)
            
            parent0.append('<div class="error">Error! Can\'t submit data. Please try again.</div>')
          }
        },
        error: function( data ) {
          log(data)
          parent0.append('<div class="error">Error! Can\'t submit data. Please try again.</div>')          
        }
      });  
    }

    
  },
  
  set_AfterAddNotification: function(){
    externalFx_HideError("connectionError");
    // watchercliFn.blinkNtimes(newElement.find(".icon-new i"),5)

    // var newElement = $("#wc-topic_list .item").first();
    // newElement.find(".body").hide();
    // newElement.find(".delete").css('visibility','hidden');

    // watchercliFn.setTopicClickEvent();
    
    watchercliFn.set_DataItemType_ClickEvent();

    watchercliFn.set_KeywordType_ClickEvent();

    watchercliFn.set_Button_ClickEvent();

    watchercliFn.set_BodyContent_ClickEvent();

    watchercliFn.set_OpenLinkToNewWindow();

    watchercliFn.set_items_height();
    
    // $("#wc-topic_list .item").first().find(".head").trigger("click");
    
    // watchercliFn.blink(".icon-new .fa-envelope")
    clientAppFn.FlashTaskbar();

    watchercliFn.update_total_messages();
    
  },
  
  isAllMessageRead: function(){
    return $(".icon-new .fa-envelope").length == 0
  },
  
  set_VisibleHide4all: function(){

    // $("#setting").toggle();
    $("#setting").hide();
    // $("#search").toggle();

    $("#log").hide();

    $(".wc-messages .delete").hide();

    $(".errorbox").hide();

    $(".total-messages").hide()

    $("#maximize-button").hide();

    // $("#search-button").hide();

    $("#connection_status div").hide();
    $("#connection_status .connecting").show();
    // $("#connection_status div").addClass('grey');
    // $("#connection_status .connecting").removeClass('grey');

  },

  disable_Backspace: function(){

    $(function(){
        /*
         * this swallows backspace keys on any non-input element.
         * stops backspace -> back
         */
        var rx = /INPUT|SELECT|TEXTAREA/i;

        $(document).bind("keydown keypress", function(e){
            if( e.which == 8 ){ // 8 == backspace
                if(!rx.test(e.target.tagName) || e.target.disabled || e.target.readOnly ){
                    e.preventDefault();
                }
            }
        });
    });

  },

  search: function(){

    try {
      const removePreviousSearch = function(){
        $('div[data-content-type].search').closest('.item').remove()
      }

      removePreviousSearch()

      var parent0 = $('#search-input').closest('#search')

      var strKeywords = $('#search-input').val()
      //alert("search " + strKeywords)

      
      parent0.find('.error,.success').remove()      

      strKeywords = (strKeywords == "z")? "%%%" : strKeywords

      if (strKeywords.length < 3){
        parent0.append('<div class="error">Please input longer keyword.</div>')
        return;
      }

      parent0.append('<div class="error">Searching...</div>')

      if (strKeywords[0] == "$"){
        watchercliFn.loadsampleSearch()
      }else{
        api_result = watchercliFn.get_search_results_from_api(strKeywords)

        // log(JSON.stringify(api_result))
        parent0.find('.error,.success').remove()

        if (api_result.notifications.length == 0){

          parent0.append('<div class="error">Sorry. There is not any FAQ matched above keyword.</div>')
          return;
        }

        watchercliFn.add_search_results_to_panel(api_result)
      }
    }
    catch(err) {

      // parent0.append(err.message)
      log(err.message);
    }            

  },


  get_search_results_from_api: function(strKeywords){
    // url = "/watchercli/" + USER + "/notification_history?keyword="+strKeywords

    url = Routes.notification_history_watchercli_path(gon.params.id,{ keyword: strKeywords })
    $.ajaxSetup({
      async: false
    });

    returnJson = ""

   $.getJSON( url, function(data) {
      // returnJson = JSON.stringify(data)
      returnJson = data

      // log(JSON.stringify(returnJson))
    })
    .done(function() {
      // log( "second success" );
    })
    .fail(function() {
    // log( "error" );
      returnJson = ""
      // log(returnJson)
      // return returnJson
    })

    // log(returnJson)
    return returnJson

  },

  add_search_results_to_panel: function(searchResults){

    // log(searchResults)
    if (! searchResults){
      return;
    }

    if (! searchResults.notifications){
      return;
    }

    searchResults.notifications.reverse()

    searchResults.notifications.forEach(function(sr){
      watchercliFn.addNewNotification_SearchResult(sr)

    })

  },

  init_search: function(keywords){

    $("#searchbox-search-icon").off('click').on('click',function(){
      watchercliFn.search();
    })

    $('#search-input').on("keypress", function(e) {
      if (e.keyCode == 13) {
          watchercliFn.search();
          return false; // prevent the button click from happening
      }
    })

    $("#searchbox-clear-icon").off('click').on('click',function(){
      $('#search-input').val('')
    })

  },

  set_items_height: function(){
    // $(".items").height($("#wc-notification").height()-$(".title-row").height()-20);
    // var height = $("#wc-notification").height()- $(".title-row").height() - 20

    var height = $("#wc-notification").height()- 50

    $("#wc-notification > div").each(function(idx){
      var obj = $(this)

      log(idx)
      log(obj)
      log(obj.is(":visible"))

      if ( obj.hasClass('title-row') ||
          obj.hasClass('items') ||
          obj.hasClass('wc-messages') 
        )
      {
        return;
      }

      if (obj.is(":visible")){
        log(obj.height())
        height -= obj.height()
      }

    })

    $(".items").css("max-height", height);
  },
  
  SetFlashing: function(){
    if ($(".items > .item").length == 0){
      clientAppFn.UnFlashTaskbar();
    }
    
  },

  showError: function(error){
    $(".errorbox#"+error).show()

    if (error == "connectionError"){
      $("#connection_status .connecting").show()
      $("#connection_status .connected").hide()

      // $("#connection_status div").addClass('grey');
      // $("#connection_status .connecting").removeClass('grey');
      // $("#connection_status .connecting i").addClass('fa-pulse');
    }
  },

  hideError: function(error){
    $(".errorbox#"+error).hide()

    if (error == "connectionError"){
      
      $("#connection_status .connecting").hide()
      $("#connection_status .connected").show()

      // $("#connection_status div").addClass('grey');
      // $("#connection_status .connected").removeClass('grey');
      // $("#connection_status .connecting i").removeClass('fa-pulse');
     
    }
  },

  set_OpenLinkToNewWindow: function()
  {
    $('.wc-messages .item a').off('click').on('click',function(ev) {
      window.open(this.href);
      ev.preventDefault(); // see post comment by @nbrooks
    });
  },

  init: function()
  { 

    watchercliFn.disable_Backspace();

    watchercliFn.init_search();
    
    watchercliFn.set_ClearAll();
    watchercliFn.set_Minimize();

    watchercliFn.set_DragFeature();
    
    watchercliFn.set_PageFontResizer();
    watchercliFn.set_FontResizer();
    
    watchercliFn.set_SettingClickEvent();
    watchercliFn.set_SearchClickEvent();
    
    watchercliFn.set_SettingElementsEvent();

    watchercliFn.set_ThemeChangeRadio();

    watchercliFn.set_theme(watchercliFn._template[0].id);
    watchercliFn.set_items_height();
    
    watchercliFn.set_VisibleHide4all();
    
    watchercliFn.SetFlashing();

    watchercliFn.afterSetTheme();

    externalFx_HideError("connectionError");
    
  }
  
};

var ZoomFont = {
  
  in: function(jqObj){
    
    jqObj.find('*').css('font-size', '12pt' )
  },
  
  out: function(jqObj){
    jqObj.find('*').css('font-size', '8pt' )
    
  },
  
  reset: function(jqObj){
    jqObj.find('*').css('font-size', '10pt' )
  }
}

var Zoom = {
  val:function(jqObj){
    var valOut = jqObj.css('zoom');
    
    if (valOut.includes("%") ){
      valOut = valOut.replace(/%/,'')
      valOut = Number(valOut)
    }else if(Number(valOut)){
      valOut = Number(valOut)*100
    }else if (valOut = "normal"){
      valOut=100
    }
    
    return valOut
  },
  
  in: function(jqObj){
    var newZoom = Zoom.val(jqObj)*1.1;
    newZoom = newZoom+"%"
    
    jqObj.animate({ 'zoom': newZoom }, 'fast');
  },
  
  out: function(jqObj){
    var newZoom = Zoom.val(jqObj)*0.9;
    newZoom = newZoom+"%"
    
    jqObj.animate({ 'zoom': newZoom}, 'fast');
    
  },
  
  reset: function(jqObj){
    var newZoom = "100%";
    
    jqObj.animate({ 'zoom': newZoom }, 'fast');
  }
  
}

jQuery(document).on('ready page:load',function(){
  watchercliFn.init();
});

