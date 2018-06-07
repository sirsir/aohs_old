function CallTracking(options){
  
  var req_id;
  
  this.logit = function(data){    
    var url = Routes.call_logging_web_tracking_log_index_path();
    $.get(url,{
      reqid: req_id,
      voice_log_id: data.voice_log_id,
      listened_sec: data.listen_sec
    });
  }
  
  function init(){
    req_id = gon.req.id || "undefined";  
  }
  
  init();
}