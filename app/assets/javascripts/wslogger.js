//= require 'marknote'

function WebOpenMQ(options){
  
  var RECONNECT_IN = 250;
  var DEBUGMODE = false;
  var nmsg = 0;
  var NULL = '\x00';
  var ws = null;
  var wsUrl = null;  
  var subid = "mysubid";
  
  this.error = false;
  this.connected = false;
  
  function createWS(){
    wsUrl = options.wsUrl;
    return new WebSocket(wsUrl);      
  }
  
  function connectString(){
    return "CONNECT\nlogin:guest\npasscode:guest\naccept-version:1.2\n\n" + NULL;     
  }
  
  function disconnectString(){
    return "DISCONNECT\n\n" + NULL;
  }
  
  function subscribeString(){
    return "SUBSCRIBE\ndestination:/" + options.subscribe.type + "/" + options.subscribe.destination + "\nid:" + subid + "\n\n" + NULL;
  }
  
  function unsubscribeString(){
    return "UNSUBSCRIBE\ndestination:/" + options.subscribe.type + "/" + options.subscribe.destination + "\nid:" + subid + "\n\n" + NULL;    
  }
  
  function bindWsEvent(){
    ws.onopen = function(evt){
      onOpen(evt);
    };
    ws.onclose = function(evt){
      onClose(evt);
    };
    ws.onmessage = function(evt){
      onMessage(evt);
    };
    ws.onerror = function(evt){
      onError(evt);
    };
  }
  
  function subscribe(){
    sendMessage(subscribeString());
  }
  
  function unsubscribe(){
    sendMessage(unsubscribeString());
  }
  
  function connect(){
    nmsg = 0;
    connected = true;
    sendMessage(connectString());
  }
  
  function disconnect(){
    sendMessage(disconnectString());
    ws.close();
  }
  
  function receiveMessage(result){
    if (typeof(result.callinfo) != 'undefined') {
      onCallStatus(result.callinfo);
    }
  }
  
  function onOpen(evt){
    //debug("MQ: open connection");
    connect();
  }
  
  function onClose(evt){
    //debug("MQ: close connection");
    setTimeout(function(){
      init();
    },RECONNECT_IN);
  }
  
  function onError(evt){
    debug("MQ: error! " + evt.data);
    appl.noty.error("Could not connect to server.");
  }
  
  function onMessage(evt){
    var freader = new FileReader();
    freader.onload = function(e) {
      //debug("MQ: received -> " + e.target.result);
      receiveMessage(getResult(e.target.result));
    };
    freader.readAsText(evt.data);
    if (zeroMessage()){
      subscribe();
    }
    incMessageCount();
  }
  
  function incMessageCount() {
    nmsg = nmsg + 1;
  }
  
  function zeroMessage() {
    return (nmsg === 0);
  }
  
  function onCallStatus(callinfo){
    
    function getStatusCode(con){
      if (con == "connected") {
        return "Talking";
      } else if (con == "disconnected") {
        return "Hangup";
      } else if (con == "xfer") {
        return "Consult";
      }
      return "";
    }
    
    function renameStatus(con){
      if(con == "xfer"){
        return "connected";
      }
      return con;
    }
    
    function parseResult(c){
      function getCallDirection(ct){
        if (ct == "Outbound") {
          return 'o';
        } else if (ct == "Inbound") {
          return 'i';
        }
        return '';
      }
      
      return {
        start_time: c.starttime,
        agent_id: c.agentid,
        ani: c.ani,
        dnis: c.dnis,
        extension: c.extension,
        direction: getCallDirection(c.calltype),
        duration_sec: (parseInt(c.duration) || 0),
        call_id: c.callid,
        channel_id: c.chanid,
        device_id: c.deviceid,
        system_id: c.systemid,
        site_id: c.siteid,
        call_status: renameStatus(c.type),
        sts_name: getStatusCode(c.type)
      };
      
    }
    
    options.onCallStatusChange(parseResult(callinfo));
  }
  
  function sendMessage(data){
    //debug("MQ: send->" + data);
    ws.send(data);
  }
  
  function getResult(t){
    
    var data = { message_type: "info" };
    
    function strToObj(line){
      var x = {}, ele = line.split(':');
      k = ele.shift();
      v = ele.join(':');
      x[k] = v;
      return x;
    }
    
    function strXMLToObj(line){
      var x = {};
      var mn = new marknote.Parser();
      var xdoc = mn.parse(line);
      var a = xdoc.getRootElement().getChildElements('callinfo')[0];
      var c = a.attributes;
      for(var i=0; i< c.length; i++){
        var b = c[i];
        x[b.name] = b.value;
      }
      return { callinfo: x };
    }
    
    function getLinePattern(line){
      if(line.match(/^(<qlogger>)(.+)(<\/qlogger>)/g)){
        return 2;
      }
      if(line.match(/^(.+)(:)(.+)$/g)){
        return 1;
      }
      return 0;
    }
    
    function convertResultString(t){
      var lines = t.split('\n');
      var l = lines.length;
      for(var i=0; i<l; i++){
        var line = lines[i];
        switch(getLinePattern(line)){
          case 1:
            data = jQuery.extend(data,strToObj(line));
            break;
          case 2:
            data = jQuery.extend(data,strXMLToObj(line));
            break;
        }
      }
    }
    
    convertResultString(t);
    return data;
  }
  
  function debug(o) {
    if (DEBUGMODE) {
      console.log(o);
    }
  }
  
  function init(){
    ws = createWS();
    ws.binaryType = "blob";
    bindWsEvent();
  }
  
  init();
}