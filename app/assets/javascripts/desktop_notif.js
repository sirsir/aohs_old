//= require 'desktop-notify'

function desktopNotification(){
  
  var isSupported = notify.isSupported;
  var permissionLevel = notify.permissionLevel();
  var permissionGranted = (permissionLevel === notify.PERMISSION_GRANTED);
  var icons = {
    'inb': 'assets/ico/ico_inb.png',
    'outb': 'assets/ico/ico_outb.png',
    'default': 'assets/ico/ico_help.png'
  }
  
  this.titleName = "AmiVoice Operator's Help";
  
  this.showCallNotification = function(msg,ico){
    var ico_url = icons['default'];
    if (icons.hasOwnProperty(ico)) {
      ico_url = icons[ico];
    }
    notify.createNotification(this.titleName,{ body: msg, icon: ico_url});
  }
  
  function requestPermission(){
    if (permissionLevel === notify.PERMISSION_DEFAULT){
      notify.requestPermission(function(){
        console.log("requestPermission!");  
      });
    }
  }
  
  function init(){
    requestPermission();
    notify.config({
      autoClose: 3000  
    });
  }
  
  init();
}
