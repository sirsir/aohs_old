//= require 'bootstrap-slider.min'
//= require '2.97a/script/soundmanager2-nodebug-jsmin'

var resizeAP;
function AudioWaveForm(id)
{
  var swf = null, srcUrl = null, dest_w = 0, dest_h = 0, scroll_w = 0, vcursor = null, vcurbox = null, loadSuccess = false, lastCursorPos = 0;

  this._loadsvg = function(data)
  {
    // draw
    swf.clear();
    swf.append(data);
    loadSuccess = true;
    
    // cursor (vetical line)
    vcursor = swf.line(0,0,0,dest_h);
    vcursor.attr({
      fill: "#00EE00",
      stroke: "#00EE00",
      strokeWidth: 1
    });
    
    // duration label at cursor
    vcurbox = swf.text(0,10,"");
    vcurbox.attr({
      fill: "#999999",
      "font-size": "0.5em"
    });
    
    swf.dblclick(function(evt){
      var x = evt.clientX;
      var sc = $("div.box-waveform");
      x = x - sc.offset().left + sc.scrollLeft();
      var p = x * ap.media.duration / dest_w;
      ap.seek(p);
    });
    
    appl.dialog.hideWaiting();
  };
  
  this.draw = function()
  {
    Snap.load(srcUrl, this._loadsvg);
    $("#svg-wave").css("display", "block");
  };
  
  this.loadSuccess = function()
  {
    return loadSuccess;
  };
  
  this.moveCursorTo = function(pos)
  {
    if (vcursor !== null) {
      // corsor position
      var xpos = Math.round(pos * dest_w / ap.media.duration);
      if(lastCursorPos != xpos && (xpos <= dest_w)){
        vcursor.animate({
          x1: xpos,
          x2: xpos,
        },10);
        vcurbox.attr({
          x: xpos + 2,
          text: appl.fmt.msecToHMS(pos).clock
        });        
      }      
      // scrollbar position
      var scroll_w = $("#box-waveform").width();
      var spos = xpos*scroll_w/dest_w;
      var o = $("#box-waveform");
      if ((spos <= scroll_w) && (spos - 10 >= 0)) {
        o.scrollLeft(spos - 10);
      }
    }
  };
  
  this.createBubble = function(channel,at_sec,text) {

    function drawTopBubble(pos){
      var box_p = pos;
      var box_l = 15;
      var box_w = text.length*4;
      var box_h = 14;
      
      var path = ["M", box_p, box_l+10, "L", box_p-1, box_l,"L",box_p+5+box_w,box_l,"L",box_p+5+box_w,box_l-box_h,"L",box_p-10,box_l-box_h,"L",box_p-10,box_l,"L",box_p-5,box_l].join(" ");
      var bx = swf.path(path);
      bx.attr({
        fill: "#20B2AA",
        //opacity: 0.5,
        strokeWidth: 0.25,
        stroke: "#20B2AA"
      });
      var tx = swf.text(box_p-8, box_l-4, text);
      tx.attr({
        "font-size": "0.5em"
      });      
    }
    
    function drawBottomBubble(){
      var box_p = pos;
      var box_l = 65;
      var box_w = 60;
      var box_h = 14;
      var path = ["M", box_p, box_l-10, "L", box_p-1, box_l, "L", box_p+box_w, box_l, "L", box_p+box_w, box_l + box_h, "L", box_p-10, box_l+box_h, "L", box_p-10, box_l,"L", box_p-5, box_l].join(" ");
      
      var bx = swf.path(path);
      bx.attr({
        fill: "#32CD32",
        //opacity: 1,
        strokeWidth: 1,
        stroke: "#32CD32"
      });
      var tx = swf.text(box_p-8, box_l+12, text);
      tx.attr({
        "font-size": "0.5em"
      });   
    }
    
    var pos = Math.floor((at_sec*1000*dest_w)/ap.media.duration);
    if (channel===0) {
      drawTopBubble(pos);
    } else {
      drawBottomBubble(pos);
    }
  };
  
  this.createSegment = function(channel,fr_sec,to_sec,text)
  {
    var fr_msec = fr_sec * 1000;
    var to_msec = to_sec * 1000;
    var s_pos = Math.floor((fr_msec*dest_w)/ap.media.duration);
    var e_pos = Math.floor((to_msec*dest_w)/ap.media.duration);
    var y_pos = 20;
    var h_box = 80;
    var w_box = e_pos - s_pos;
    var segm = swf.rect(s_pos,y_pos,w_box,h_box);
    segm.attr({
      fill: "#FFEC8B",
      opacity: '0.5'
    });
    var segm_t = swf.text(s_pos + 5,y_pos + 15,text);
    segm_t.attr({
      color: "#595959",
      'font-size': '1em'
    });
    var o = {
      fsec: fr_sec,
      tsec: to_sec,
      xpos: s_pos,
      ypos: y_pos,
      wbox: w_box,
      hbox: h_box,
      text: text
    };
  };
  
  this.removeSegment = function(){
    
  };
  
  this.removeAllSegments = function(){
    
  };
  
  this.hideSegment = function(){
    
  };
  
  this.hideAllSegments = function(){
    
  };
  
  this.createPosition = function(at_sec,title)
  {
    var at_msec = at_sec * 1000;
    var s_pos = Math.floor((at_msec*dest_w)/ap.media.duration);
    var e_pos = s_pos + 12;
    var h_box = 12;
    var y_pos = dest_h - h_box;
    var w_box = e_pos - s_pos;
    var posi = swf.image("/assets/pin56.png",s_pos,y_pos,w_box,h_box);
    var otitle = Snap.parse("<title>" + title + "</title>");
    posi.append(otitle);
  };
  
  this.getPxPosition = function(at_sec)
  {
    var at_msec = at_sec * 1000;
    var s_pos = Math.floor((at_msec*dest_w)/ap.media.duration);
    return s_pos;
  };
  
  this.clear = function(){
    swf.clear();
  };
  
  this.adjustSize = function(){
    var fnResize = function(){
      var oc = $("div.panel-audioview");
      if(oc.length > 0){
        var wc = oc.width();
        var ow = $("#box-waveform");
        ow.width(wc);
        scroll_w = wc;
      }
    };
    fnResize();
  };
  
  function getUrl()
  {
    return Routes.waveform_voice_log_path({ id: id })+"?w="+dest_w+"&h="+dest_h;
  }
  
  function resize()
  {
    var fnResize = function(){
      /* containner size */
      var oc = $("div.panel-audioview");
      if(oc.length > 0){
        var wc = oc.width();
        var ow = $("#box-waveform");
        ow.width(wc);
        scroll_w = wc;
      }
    };
    fnResize();
    $(window).on('resize', fnResize);
  }
  
  function calcSize()
  {
    var t = $("#box-waveform"); /* outer */
    var p = $("#box-waveform-inner"); /* svg-waveform */
    var q = $("#box-events"); /* topic */
    var r = $("#box-topics");
    var s_h = 4; /* scroll bar */
    var sw = screen.width;
    p.width(sw);
    q.width(sw);
    r.width(sw);
    dest_w = p.width();
    dest_h = t.height() - q.height() - s_h;
    scroll_w = t.width();
    p.height(dest_h);
  }
  
  function init(){
    resize();
    calcSize();
    swf = Snap("#svg-wave");
    srcUrl = getUrl();
    loadSuccess = false;
  }
  
  init();
}

/* Audio Player */

var ap = {
  soundID: 'current',
  _soundmg: null,
  _howler: null,
  _audioSlider: null,
  _intervalPx: null,
  awf: null,
  media: {
    isReady: false,
    pauseOn: false
  },
  resizeDelay: 10,
  settings: {
    fastStepSec: 10,
    showAudioWave: false,
    volume: 50,
    defaultVolume: 50,
    balance: 0,
    playBackRate: 1.0,
    defaultPlayBackRate: 1.0
  },
  
  _debug: function(x){
    if(true){ console.log(x); }
  },
  
  _setInitOptions: function(opts){
    if (isPresent(opts.showWaveForm)) {
      ap.settings.showAudioWave = opts.showWaveForm;
    }
    if (isPresent(opts.autoPlay)){
      ap.settings.autoPlay = opts.autoPlay;
    }
  },

  _doUpdateTracking: function(){
    /* update tracking logs */
    jQuery.get(Routes.call_logging_web_tracking_log_index_path(),{
      voice_log_id: ap.attr.id,
      listened_sec: 0,
      reqid: gon.req.id
    });
  },
  
  _createAudioTrackSlider: function(sfrom, sTo, sCur){
    ap._audioSlider.slider('destroy');
    ap._audioSlider = $("#au-input-slider").slider({
      min: sfrom, max: sTo, value: sCur
    }).on('slideStop change',function(e){
      if(isNumeric(e.value)){
        ap.seek(e.value);
      } else {
        ap.seek(e.value.newValue); 
      }
    });
    ap._audioSlider.slider('enable');
  },

  _resizeAudioSlider: function(){
    var p_width = $("#audioplayer").width();
    var wl = $("div.btn-group-left").width();
    var wr = $("div.btn-group-right").width();
    var wp = $("#btn-playing-rate").width();
    var p_wrem = wl + wr + wp + 1;
    $("#slider-audio").width(p_width-p_wrem);
    $("#slider-audio .slider-horizontal").width(p_width-p_wrem);
  },
  
  _onFileLoadSuccess: function(){
    ap.media.isReady = true;
    ap.media.duration_text = appl.fmt.msecToHMS(ap.media.duration).clock;
    ap._createAudioTrackSlider(0, ap.media.duration, 0);
    ap._updateDurationLabel(ap.media.duration);
    ap._resizeAudioSlider();
    if(ap.settings.autoPlay === true){
      ap.play();
    } else {
      ap._debug("auto play is disabled");
    }
    ap._debug("load completed. duration=" + ap.media.duration);
    appl.dialog.hideWaiting();
  },
  
  _onFileLoadError: function(){
    ap.media.isReady = false;
    ap.media.duration_text = "--:--";
    appl.noty.error("This audio file does not exist or your browser does not support. Please try to refresh page.");
    appl.dialog.hideWaiting();
  },
  
  _startInvPx: function(){
    if(ap._intervalPx == null){
      ap._intervalPx = setInterval(function(){
        //ap.media.position = ap._howler.seek()*1000.0;
        ap.media.position = ap._soundmg.position * 1;
        ap._onSoundPlaying();
      },200);
    }
  },
  
  _stopInvPx: function(){
    if(ap._intervalPx != null){
      clearInterval(ap._intervalPx);
      ap._intervalPx = null;
    }
  },
  
  _onSoundStart: function(){
    ap._setControlPlayStart();
    ap._doUpdateTracking();
  },
  
  _onSoundPlaying: function(){
    // while sound playing
    var position = ap.media.position;
    ap.media.curDuration = position;
    ap._audioSlider.slider('setValue', position);
    ap._updateDurationLabel(position);
    if (ap.settings.showAudioWave) {
      ap.awf.moveCursorTo(position);
    }
  },
  
  _onSoundStopped: function(){
    ap._setControlPlayStop();
  },
  
  _updateDurationLabel: function(secs){
    $("#au-duration").text(appl.fmt.msecToHMS(secs).clock + "/" + ap.media.duration_text);
    try {
      callInfo.highlightRowAtSec(secs/1000.0);
    } catch(e){
      console.log(e);
    }
  },

  _setControlPlayStop: function(){
    $("#btn-pause").css("display","none");
    $("#btn-play").css("display","inline-block");
  },
  
  _setControlPlayStart: function(){
    $("#btn-play").css("display","none");
    $("#btn-pause").css("display","inline-block");  
  },
  
  _setControlPlayPause: function(){
    $("#btn-pause").css("display","none");
    $("#btn-play").css("display","inline-block");    
  },
  
  _isReady: function(){
    /* load success */
    return ap.media.isReady;  
  },
  
  _isReadyToPlay: function(){
    /* ready to play */ 
    var ca = ap.media.isReady && (ap.settings.showAudioWave === false) && (ap.awf === null);
    var cb = ap.media.isReady && (ap.settings.showAudioWave === true) && (ap.awf !== null) && ap.awf.loadSuccess;
    return (ca || cb);  
  },

  _isCorrectPosition: function(pos){
    if(Object.isNumber(pos)){
      return ((pos >= 0) && (pos <= ap.media.duration));
    }
    return false;
  },
  
  _isPlaying: function(){
    if(ap._isReady()){
      //return (ap._howler.playing());
      return (ap._soundmg.playState == 1);
    }
    return false;
  },
  
  _isPause: function(){
    return ap.media.pauseOn;
  },
  
  _setVolume: function(cVol){
    ap.settings.volume = cVol;
    if (ap._isReady()) {
      ap._debug("changed volume to " + ap.settings.volume);
      //ap._howler.volume(ap.settings.volume/100.0);
      ap._soundmg.setVolume(ap.settings.volume);
    }
  },

  _setPan: function(p){
    ap.settings.balance = p || ap.settings.balance;
    if (ap._isReady()) {
      //ap._smplayer.setPan(ap.settings.balance);
    }
  },
  
  _setPlaybackSpeed: function(cRate){
    if((cRate >= 0.1) && (cRate <= 4.0)){
      ap.settings.playBackRate = cRate;
      if (ap._isReady()){
        //ap._howler.rate(cRate);
        ap._soundmg.setPlaybackRate(cRate);
      }
    }
  },
  
  _forceUpdatePlayingProp: function(){
    //ap._howler.play();
    //ap._howler.volume(ap.settings.volume);
    ap._soundmg.setVolume(ap.settings.volume);
    ap._setPlaybackSpeed(ap.settings.playBackRate);  
  },
  
  setAudioUrl: function(url, opts){
    function playUsingHowler(){
      ap._howler = new Howl({
        src: [url],
        autoplay: false,
        loop: false,
        volume: 0.8,
        onload: function(){
          ap.media.duration = ap._howler.duration()*1000.0;
          ap._onFileLoadSuccess();
        },
        onloaderror: function(){
          ap.media.duration = 0;
          ap._onFileLoadError();
        },
        onplayerror: function(){
          ap.media.duration = 0;
          ap._onFileLoadError();
        },
        onpause: function(){
          ap.media.pauseOn = true;
          ap._stopInvPx();
        },
        onplay: function(){
          ap.media.pauseOn = false;
          ap._onSoundStart();
          ap._startInvPx();
        },
        onend: function(){
          ap.media.pauseOn = false;
          ap._onSoundStopped();
          ap._stopInvPx();
        },
        onstop: function(){
          ap.media.pauseOn = false;
          ap._onSoundStopped();
          ap._stopInvPx();
        },
        onseek: function(){
          ap._onSoundStart();
          ap._startInvPx();
        }
      });
    }
    
    function playUsingSMP(){
      var smOpts = {
        id: ap.soundID,
        url: url,
        volume: 50,
        autoLoad: true,
        autoPlay: false,
        onload: function(){
          ap.media.duration = ap._soundmg.duration*1;
          ap._onFileLoadSuccess();
        },
        onerror: function(){
          ap.media.duration = 0;
          ap._onFileLoadError();
        },
        onplay: function(){
          ap._onSoundStart();
          ap._startInvPx();
        },
        onpause: function(){
          ap.media.pauseOn = true;
          ap._stopInvPx();
        },
        onresume: function(){
          ap.media.pauseOn = false;
          ap._startInvPx();
        },
        onstop: function(){
          ap.media.pauseOn = false;
          ap._onSoundStopped();
          ap._stopInvPx();
        },
        onfinish: function(){
          ap._onSoundStopped();
          ap._stopInvPx();
        }
      };
      soundManager.destroySound(ap.soundID);
      ap._soundmg = soundManager.createSound(smOpts);
    }
    
    appl.dialog.showWaiting();
    ap._setInitOptions(opts);
    ap.reset();
    ap.media.url = url;
    ap.media.pauseOn = false;
    //playUsingHowler();
    playUsingSMP();
    ap.media.isReady = true;
  },
  
  setAttrs: function(id,callId){
    ap.attr = {
      id: id,
      callId: callId
    };
  },

  reset: function(){
    function destroySound(){
      try{
        ap._howler.unload();
      } catch(e){}
      try{
        ap._soundmg.destroy();
      } catch(e){}
    }
    
    ap.stop();
    if (ap.awf !== null) { ap.awf.clear(); }
    destroySound();
    ap.attr = {};
    ap.media = {
      duration: 0,
      curDuration: 0,
      position: 0,
      url: null,
      isReady: false
    };
  },
  
  play: function(){    
    if(ap._isReadyToPlay()){
      try {
        ap._soundmg.play();
        ap._forceUpdatePlayingProp();
        ap._setControlPlayStart();
        appl.dialog.hideWaiting();
      } catch(e){ ap._debug(e); }
    }
  },

  playAt: function(t){
    /* play at time 00:00 */
    setTimeout(function(){
      ap.seek(appl.sToms(appl.timeToSec(t)));
    },500);
  },
  
  playAtSec: function(s){
    /* play at sec */
    ap.seek(appl.sToms(s));
  },
  
  playAtMilSec: function(s){
    /* plat at msec */
    ap.seek(s);
  },
  
  pause: function(){
    if(ap._isReady()){
      //ap._howler.pause();
      ap._soundmg.pause();
      ap._setControlPlayPause();
    }
  },

  resume: function(){
    if(ap._isReady()){
      //ap._howler.play();
      ap._soundmg.resume();
      ap._setControlPlayStart();
      ap._forceUpdatePlayingProp();
    }
  },
  
  stop: function(){
    if(ap._isReady()){
      //ap._howler.stop();
      ap._soundmg.stop();
    }
  },

  seek: function(pos){
    if(ap._isCorrectPosition(pos)){
      //ap._howler.seek(pos/1000.0);
      ap._soundmg.setPosition(pos);
      if(!ap._isPlaying()){
        ap.play();
      } else {
        if(ap.media.pauseOn){
          ap.resume();
        }
      }
    } else {
      ap._debug("invalid seek position = " + pos);
      ap._debug(pos);
    }
  },
  
  fastBackward: function(){
    ap.seek(ap.position - appl.sToms(ap.settings.fastStepSec));
  },
  
  fastForward: function(){
    ap.seek(ap.position + appl.sToms(ap.settings.fastStepSec));
  },
  
  currentPosition: function(){
    return appl.fmt.msecToHMS(ap.media.curDuration).clock;
  },
  
  loadWaveForm: function(id, opts){
    ap.awf = new AudioWaveForm(id, opts);
    ap.awf.draw();
  },
  
  _setVolumeSlider: function(){
    $("#btn-audio-volume").val(ap.settings.volume).on('click',function(){
      $("#slider-volume").toggleClass('hide-input-range');
      ap._resizeAudioSlider();
    });
    $("#slider-volume input[type=range]").off('change').on('change',function(){
      ap._setVolume(parseInt($(this).val()));
    });
  },
  
  _setPanSlider: function(){
    $("#btn-audio-pan").on('click',function(){
      $("#slider-pan").toggleClass('hide-input-range');
      ap._resizeAudioSlider();
    });
    $("#slider-pan input[type=range]").off('change').on('change',function(){
      ap._setPan(parseInt($(this).val()) - 100);
    });
  },
  
  _setPlayBackRate: function(){
    $("#btn-playing-rate").on('click',function(){
      $("#slider-playing-rate").toggleClass('hide-input-range');
      ap._resizeAudioSlider();
    });
    $("#slider-playing-rate input[type=range]").off('change').on('change',function(){
      var cRate = parseFloat($(this).val());
      ap._setPlaybackSpeed(cRate);
      $("#btn-playing-rate").html(cRate + "x");
    });
  },

  _onResizeWindow: function(){
    function fnResizeFinish(){
      ap._resizeAudioSlider();
    }
    clearTimeout(resizeAP);
    resizeAP = setTimeout(fnResizeFinish, ap.resizeDelay);
  },
  
  _onPageClose: function(){
    $(window).on('unload',function(){
      try {
        ap._howler.unload();
      } catch(e){}
      try {
        soundManager.destroySound(ap.soundID);
      } catch(e){}
    });
  },
  
  init: function(){
    
    function createAudioSlider(){
      ap._audioSlider = $("#au-input-slider").slider();
      ap._audioSlider.slider('disable');      
    }
    
    function bindEventButtons(){
      $("#btn-play").on('click',function(){
        ap.play();
      });
      $("#btn-pause").on('click',function(){
        ap.pause();
      });
      $("#btn-fast-backward").on('click',function(){
        ap.fastBackward();
      });
      $("#btn-fast-forward").on('click',function(){
        ap.fastForward();
      });
      $("#btn-audio-waveform").on('click',function(){ });
    }
    
    function setWindowResize(){
      $(window).resize(function(){
        ap._onResizeWindow();
      });
    }
    
    function resetControl(){
      ap._setVolumeSlider();
      ap._setPanSlider();
      ap._setPlayBackRate();
      ap._resizeAudioSlider();
    }
    
    createAudioSlider();
    bindEventButtons();
    resetControl();
    setWindowResize();
    ap._onPageClose();
  }
};

if(soundManager != undefined){
  soundManager.setup({
    debugMode: false,
    preferFlash: false
  });
}

jQuery(document).on('ready page:load',function(){ ap.init(); });
