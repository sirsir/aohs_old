var fnNt = {
  send: function(){
    function getFields(){
      var ds = {};
      ds.level = $("#notif-level option:selected").val();
      ds.agent_name = $("#notif-target-user").val();
      ds.title = $("#notif-title").val();
      ds.icon = $("#notif-icon-name option:selected").val();
      ds.message = $("#notif-detail").val();
      ds.timeout = $("#notif-timeout option:selected").val();
      return ds;
    }
    
    function postMessage(ds){
      var url = Routes.client_notify_webapi_index_path({ do_act: 'send' });
      jQuery.post(url,ds,function(data){
        if(data.success){
          appl.noty.info("Message has been send.");
        } else {
          appl.noty.error(data.message.join(","));
        }
      });
    }
    var ds = getFields();
    postMessage(ds);
  },
  
  init: function(){
    $("button#btn-submit").on('click',function(){
      fnNt.send();  
    });
  }
};

jQuery(document).on('ready page:load',function(){ fnNt.init(); });