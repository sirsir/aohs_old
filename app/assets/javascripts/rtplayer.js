var AudioContext = window.AudioContext || window.webkitAudioContext;

var CbAudioContext = new AudioContext();

var CbPlayer = {
  ds: {},
  
  _intervalFileBuffer: null,
  _intervalPlayLoop: null,
  _intervalFileBufferSec: 1000,
  _audioBuffers: [],
  _currentSessionName: null,
  _currentFileIndex: null,
  _prevFileIndex: -1,
  _loadedBufferCount: 0,
  _playedBufferCount: 0,
  _isLoadingBuffer: false,
  _stimeLoadBuffer: null,
  _timeGapBuffer: 0,
  _requestFileTryCount: 0,
  _timeInvervalLoadFile: null,
  _requireHeaderFile: true,
  _playNextTime: 0,
  
  /* player state
    0 -> not ready
    1 -> initial
    2 -> started (playing)
    9 -> stopped
  */
  state: 0,

  requestTryCount: 0,
  
  volume:{
    /* range 0 - 100 to 0.0 - 1.0 */
    value: 0.5,
    current: function(){
      return CbPlayer.volume.value * 100.0;  
    },
    set: function(v){
      CbPlayer.volume.value = v / 100.0;
    }
  },
  
  log: function(l){
    if(gon.params.debug === "true"){
      console.log(l);  
    }
  },
  
  pingServer: function(){
    //var url = gon.settings.stream.rootUrl + "/qlogger";
  },
  
  isPlaying: function(){
    return (CbPlayer.state >= 1 && CbPlayer.state <= 8);  
  },
  
  isStopped: function(){
    return (CbPlayer.state == 9);  
  },

  listen: function(cf){
    var DELAY_START = 500; /* wait for buffer at server */
    var MAX_RETRY = 3;
    
    function playSourceBuffer(){
      if (!CbPlayer.isStopped() && !CbPlayer._audioBuffers.isEmpty()){
        var arrayBuffer = CbPlayer._audioBuffers.pop();
        try {
          if(arrayBuffer !== undefined){
            var playBuffer = function(buf){
              var src = CbAudioContext.createBufferSource();
              var gainNode = CbAudioContext.createGain();
              var cTime = CbAudioContext.currentTime;
              src.buffer = buf;
              src.connect(gainNode);
              gainNode.gain.value = CbPlayer.volume.value;
              gainNode.connect(CbAudioContext.destination);
              src.loop = false;
              src.onended = function(){
                src.stop(0);
                src.disconnect(0);
                src = null;
              };
              if(CbPlayer._playNextTime === 0){
                CbPlayer._playNextTime += cTime;
              } else {
                CbPlayer._playNextTime += 0.0001;
              }
              src.start(CbPlayer._playNextTime, 0.0001);
              CbPlayer._playNextTime += (src.buffer.duration).round(0);
            };
            var decodeError = function(e){
              console.log(e);
            };
            CbAudioContext.decodeAudioData(arrayBuffer.buffer, playBuffer, decodeError);             
          }
        } catch(e){
          console.log(e);
        }
        CbPlayer._playedBufferCount++;
        CbPlayer.log("played count:" + CbPlayer._playedBufferCount + ", time:" + CbPlayer._playNextTime);
      }
    }

    function getSourceBuffer(){
      var dataSourceURL = function(){
        return gon.settings.stream.rootUrl + "/file/" + CbPlayer._currentSessionName + "/" + CbPlayer._currentFileIndex + ".wav" + "?who=cb&hdrf=" + CbPlayer._requireHeaderFile + "&t=" + moment().format("mmss.SS");
      };
      
      CbPlayer.log("waiting: index=" + CbPlayer._currentFileIndex);
      CbPlayer._stimeLoadBuffer = new Date();
      CbPlayer._isLoadingBuffer = true;
      CbPlayer._timeGapBuffer = 0;
      
      var request = new window.XMLHttpRequest();
      request.open('GET', dataSourceURL(), true);
      request.responseType = 'arraybuffer';

      request.addEventListener("load", function(){
        CbPlayer._isLoadingBuffer = false;
        CbPlayer._timeGapBuffer = new Date() - CbPlayer._stimeLoadBuffer;
        if(CbPlayer._timeGapBuffer >= 1000){
          /* fix:take more time to process add wait-msec */
          var amsec = 500;
          CbPlayer.log('added wait-time:' + amsec);
          CbPlayer._timeInvervalLoadFile = moment(CbPlayer._timeInvervalLoadFile).add(amsec ,'milliseconds');
        } else {
          if(CbPlayer._timeGapBuffer <= 300){
            var rmsec = 500;
            CbPlayer.log('subtract wait-time:' + rmsec);
            CbPlayer._timeInvervalLoadFile = moment(CbPlayer._timeInvervalLoadFile).subtract(rmsec ,'milliseconds');
          }
        }
        try {
          var resp = this;
          if (resp.status == 200 && !CbPlayer.isStopped()){
            var arrayBuffer = resp.response;
            CbPlayer._requestFileTryCount = 0;
            CbPlayer._loadedBufferCount++;
            CbPlayer._currentFileIndex++;
            CbPlayer._prevFileIndex = CbPlayer._currentFileIndex - 1;
            if (arrayBuffer){
              var byteArray = new Uint8Array(arrayBuffer);
              if(byteArray.length > 8000){
                CbPlayer._audioBuffers.insert(byteArray,0);
                CbPlayer.log("loaded: index=" + CbPlayer._prevFileIndex + ", size=" + byteArray.length + ", msec=" + CbPlayer._timeGapBuffer);            
              }
            }
          } else {
            if (resp.status == 204) {
              CbPlayer.stop();
            } else if((resp.status >= 500) && (resp.status < 600)){
              CbPlayer._requestFileTryCount++;
              if(CbPlayer._requestFileTryCount > MAX_RETRY){
                CbPlayer.stop();
                appl.noty.error("Failed to connect streaming server.");
              }
            }
          }          
        } catch (e){ console.log('Request load error'); console.log(e); }
      });
      
      request.addEventListener("error", function(){
        CbPlayer._requestFileTryCount++;
        CbPlayer._isLoadingBuffer = false;
        if(CbPlayer._requestFileTryCount > MAX_RETRY){
          appl.noty.error("Request error. Please try again.");
          CbPlayer.stop();
        } else {
          if(CbPlayer._requestFileTryCount > 1){
            CbPlayer._currentFileIndex++;
            CbPlayer.log("try next: " + CbPlayer._currentFileIndex);
          }
        }
      });
      
      request.addEventListener("abort", function(){
        CbPlayer._requestFileTryCount++;
        CbPlayer._isLoadingBuffer = false;
        if(CbPlayer._requestFileTryCount > MAX_RETRY){
          appl.noty.error("Request abort. Please try again");
          CbPlayer.stop();
        } else {
          if(CbPlayer._requestFileTryCount > 1){
            CbPlayer._currentFileIndex++;
            CbPlayer.log("try next: " + CbPlayer._currentFileIndex);
          }
        }
      });
      
      try {
        request.send(null);    
      } catch(e){}
    }
    
    function initPlay(rs){
      var result = rs.result;
      if (result.result == "success"){
        CbPlayer.ds = result;
        CbPlayer._currentSessionName = result.session_id;
        CbPlayer._currentFileIndex = result.start_index - 1;
        if(CbPlayer._currentFileIndex < 0){ CbPlayer._currentFileIndex = 0; }
        CbPlayer._intervalFileBufferSec = result.buffer_interval_sec;
        CbPlayer._prevFileIndex = -1; 
        CbPlayer._loadedBufferCount = 0;
        CbPlayer._playedBufferCount = 0;
        CbPlayer._audioBuffers = [];
        CbPlayer._isLoadingBuffer = false;
        CbPlayer._requestFileTryCount = 0;
        CbPlayer._timeInvervalLoadFile = new Date();
        CbPlayer._requireHeaderFile = true;
        CbPlayer._playNextTime = 0;
        setTimeout(function(){
          CbPlayer._intervalFileBuffer = setInterval(function(){
            var cTime = new Date();
            var gTime = (CbPlayer._intervalFileBufferSec * 1000) - 0;
            var wTime = (cTime - CbPlayer._timeInvervalLoadFile);
            if(wTime >= gTime){
              if(!CbPlayer._isLoadingBuffer && (CbPlayer._currentFileIndex > CbPlayer._prevFileIndex)){
                CbPlayer._timeInvervalLoadFile = cTime;
                getSourceBuffer();
              }
            }
          }, 1);
          CbPlayer._intervalPlayLoop = setInterval(function(){
            playSourceBuffer();
          }, 5);
        }, DELAY_START);
        CbPlayer.state = 2;
      } else {
        CbPlayer.state = 0; 
      }
    }
    
    function makeStreamRequest(){
      var url = gon.settings.stream.rootUrl + "/listen/" + cf.call_id;
      var arg = {
        agent_id: cf.user_id,
        sys: cf.sys,
        dev: cf.dev,
        chn: cf.chn,
        ext: cf.ext,
        t: (new Date()).getTime()
      };
      var opts = {
        url: url,
        data: arg,
        timeout: 5000,
        success: function(data){
          if(data.result.result == "success"){
            initPlay(data);
            appl.dialog.hideWaiting();            
          } else {
            CbPlayer.requestTryCount++;
            if(CbPlayer.requestTryCount >= MAX_RETRY){
              /* failed reconnect */
              appl.noty.error("Cannot open streaming connection from server.");
              appl.dialog.hideWaiting();              
            } else {
              /* retry connect */
              setTimeout(function(){
                makeStreamRequest();
              },1000);
            }
          }
        },
        error: function(xhr, status, error){
          appl.noty.error("Cannot initial streaming connection from server.");
          appl.dialog.hideWaiting();
        }
      };
      CbPlayer.state = 1;
      appl.dialog.showWaiting();
      jQuery.ajax(opts);
    }
    
    /* make stream request */
    CbPlayer.requestTryCount = 0;
    makeStreamRequest();
  },
  
  stop: function(){
    CbPlayer.state = 9;
    CbPlayer._isLoadingBuffer = false;
    try {
      clearInterval(CbPlayer._intervalPlayLoop);
    } catch(e) {}
    try {
      clearInterval(CbPlayer._intervalFileBuffer);
    } catch(e) {}
  }
};
